import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techezm_attendance_portal/models/geofence_settings.dart';
import 'package:techezm_attendance_portal/models/wifi_settings.dart';
import 'auth_provider.dart';

/// Provides the current geofence settings stored in Firestore.
final geofenceSettingsProvider = FutureProvider<GeofenceSettings?>((ref) async {
  final firestore = ref.read(firestoreServiceProvider);
  return firestore.getGeofenceSettings();
});

/// Provides the current Wi‑Fi settings stored in Firestore.
final wifiSettingsProvider = FutureProvider<WifiSettings?>((ref) async {
  final firestore = ref.read(firestoreServiceProvider);
  return firestore.getWifiSettings();
});