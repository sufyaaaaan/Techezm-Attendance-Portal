import 'package:geolocator/geolocator.dart';
import 'package:techezm_attendance_portal/models/geofence_settings.dart';
import 'package:techezm_attendance_portal/services/location_service.dart';
import 'package:techezm_attendance_portal/services/wifi_service.dart';
import 'package:network_info_plus/network_info_plus.dart';



/// Encapsulates business logic for validating whether an employee can mark
/// attendance. This includes verifying their location is within the allowed
/// geofence and checking that they are connected to the permitted Wi‑Fi
/// network.
class AttendanceValidationResult {
  final bool insideArea;
  final bool wifiMatched;
  final double locationAccuracy;
  final String? currentWifiName;

  AttendanceValidationResult({
    required this.insideArea,
    required this.wifiMatched,
    required this.locationAccuracy,
    required this.currentWifiName,
  });
}

class AttendanceService {
  final LocationService _locationService;
  final WifiService _wifiService;

  AttendanceService({
    LocationService? locationService,
    WifiService? wifiService,
  })  : _locationService = locationService ?? LocationService(),
        _wifiService = wifiService ?? WifiService();

  /// Validates whether the device is eligible to mark attendance based on
  /// [geofence] settings and [allowedWifiName]. Returns a
  /// [AttendanceValidationResult] containing the current state.
  Future<AttendanceValidationResult> validate({
    required GeofenceSettings geofence,
    required String allowedWifiName,
  }) async {
    print("=== VALIDATION STARTED ===");

    // ---------------------------------------------------------
    // STEP 0: REQUEST PERMISSIONS (THIS IS WHAT YOU WERE MISSING)
    // ---------------------------------------------------------
    print("Requesting location permission...");

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      print("ERROR: Location permission permanently denied.");
      return AttendanceValidationResult(
        insideArea: false,
        wifiMatched: false,
        currentWifiName: null,
        locationAccuracy: 9999,
      );
    }

    if (permission == LocationPermission.denied) {
      print("ERROR: User denied location permission.");
      return AttendanceValidationResult(
        insideArea: false,
        wifiMatched: false,
        currentWifiName: null,
        locationAccuracy: 9999,
      );
    }

    print("Permission granted.");

    // -------------------------------
    // STEP 1: GET LOCATION
    // -------------------------------
    print("Getting location...");
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("Location received: ${position.latitude}, ${position.longitude}");
      print("Accuracy: ${position.accuracy} meters");
    } catch (e) {
      print("ERROR getting location: $e");
      return AttendanceValidationResult(
        insideArea: false,
        wifiMatched: false,
        currentWifiName: null,
        locationAccuracy: 9999,
      );
    }

    // -------------------------------
    // STEP 2: GET WIFI
    // -------------------------------
    print("Getting WiFi name...");
    String? wifiName;
    try {
      wifiName = await NetworkInfo().getWifiName();

      print("RAW WiFi value: '$wifiName'");

      // Android returns SSID with quotes → remove them
      if (wifiName != null) {
        wifiName = wifiName!.replaceAll('"', '').trim();
      }

      print("Cleaned WiFi: '$wifiName'");
    } catch (e) {
      print("ERROR reading WiFi name: $e");
    }

    // -------------------------------
    // STEP 3: DISTANCE CALCULATION
    // -------------------------------
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      geofence.latitude,
      geofence.longitude,
    );

    print("Distance from office: $distance meters");
    print("Radius allowed: ${geofence.radius}");

    final insideArea = distance <= geofence.radius;
    final wifiMatched = wifiName != null &&
        wifiName!.toLowerCase() == allowedWifiName.toLowerCase();

    print("Inside geofence: $insideArea");
    print("WiFi matched: $wifiMatched");
    print("=== VALIDATION FINISHED ===");

    return AttendanceValidationResult(
      insideArea: insideArea,
      wifiMatched: wifiMatched,
      currentWifiName: wifiName,
      locationAccuracy: position.accuracy,
    );
  }

}