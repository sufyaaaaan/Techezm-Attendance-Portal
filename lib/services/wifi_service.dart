import 'package:network_info_plus/network_info_plus.dart';

/// Service responsible for obtaining network information such as the connected
/// Wi‑Fi name.
class WifiService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Returns the currently connected Wi‑Fi name (SSID).
  ///
  /// On Android the Wi‑Fi name may be surrounded by quotes as described in
  /// the network_info_plus documentation【85169722705482†L92-L108】. If null,
  /// it indicates the device is not connected to Wi‑Fi.
  Future<String?> getWifiName() async {
    final name = await _networkInfo.getWifiName();
    // Remove surrounding quotes if present.
    if (name != null && name.length > 1 && name.startsWith('"') && name.endsWith('"')) {
      return name.substring(1, name.length - 1);
    }
    return name;
  }
}