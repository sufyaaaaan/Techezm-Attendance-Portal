import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techezm_attendance_portal/models/geofence_settings.dart';
import 'package:techezm_attendance_portal/models/wifi_settings.dart';
import 'package:techezm_attendance_portal/providers/settings_provider.dart';

import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();
  final TextEditingController _wifiNameController = TextEditingController();

  bool _loading = false;
  String? _error;

  final Color primaryBlue = const Color(0xFF072957);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final geofence = await ref.read(geofenceSettingsProvider.future);
    final wifi = await ref.read(wifiSettingsProvider.future);

    if (geofence != null) {
      _latitudeController.text = geofence.latitude.toString();
      _longitudeController.text = geofence.longitude.toString();
      _radiusController.text = geofence.radius.toString();
    }

    if (wifi != null) {
      _wifiNameController.text = wifi.wifiName;
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final firestore = ref.read(firestoreServiceProvider);

      final geofence = GeofenceSettings(
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        radius: double.parse(_radiusController.text.trim()),
      );

      final wifi = WifiSettings(
        wifiName: _wifiNameController.text.trim(),
      );

      await firestore.setGeofenceSettings(geofence);
      await firestore.setWifiSettings(wifi);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue.withOpacity(0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ==============================
              //        GEOFENCE SECTION
              // ==============================
              const Text(
                "Geofence Settings",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            keyboardType: TextInputType.number,
                            decoration: _inputStyle("Latitude"),
                            validator: (v) =>
                            v == null || v.isEmpty ? 'Enter latitude' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            keyboardType: TextInputType.number,
                            decoration: _inputStyle("Longitude"),
                            validator: (v) =>
                            v == null || v.isEmpty ? 'Enter longitude' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: _inputStyle("Radius (meters)"),
                      validator: (v) =>
                      v == null || v.isEmpty ? 'Enter radius' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ==============================
              //        WIFI SECTION
              // ==============================
              const Text(
                "Wi-Fi Settings",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                child: TextFormField(
                  controller: _wifiNameController,
                  decoration: _inputStyle("Allowed Wi-Fi Name (SSID)"),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Enter Wi-Fi name' : null,
                ),
              ),

              const SizedBox(height: 24),

              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Save Settings",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
