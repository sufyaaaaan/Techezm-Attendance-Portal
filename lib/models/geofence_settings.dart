

/// Model representing geofence configuration.
///
/// The geofence is defined by its [latitude], [longitude] and [radius] (in
/// meters). When employees mark attendance their current coordinates are
/// compared against this configuration.
class GeofenceSettings {
  final double latitude;
  final double longitude;
  final double radius;

  GeofenceSettings({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory GeofenceSettings.fromMap(Map<String, dynamic> data) {
    return GeofenceSettings(
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      radius: (data['radius'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }
}