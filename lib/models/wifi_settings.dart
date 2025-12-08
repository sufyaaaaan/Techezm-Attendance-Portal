/// Model representing allowed Wi‑Fi configuration.
class WifiSettings {
  final String wifiName;

  WifiSettings({required this.wifiName});

  factory WifiSettings.fromMap(Map<String, dynamic> data) {
    return WifiSettings(
      wifiName: data['wifiName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'wifiName': wifiName};
  }
}