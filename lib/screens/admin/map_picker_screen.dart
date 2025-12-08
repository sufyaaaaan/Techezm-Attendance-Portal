import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _controller;
  LatLng? _selectedLocation;

  static const LatLng initialPosition = LatLng(24.8607, 67.0011); // Karachi default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Office Location")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: initialPosition,
              zoom: 14,
            ),
            onTap: (LatLng pos) {
              setState(() => _selectedLocation = pos);
            },
            markers: _selectedLocation == null
                ? {}
                : {
              Marker(
                markerId: const MarkerId("selected"),
                position: _selectedLocation!,
              ),
            },
            onMapCreated: (controller) {
              _controller = controller;
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedLocation == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Tap on the map to select location"),
                    ),
                  );
                  return;
                }

                Navigator.pop(context, _selectedLocation);
              },
              child: const Text("Confirm Location"),
            ),
          ),
        ],
      ),
    );
  }
}
