
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FarmLocationPickerScreen extends StatefulWidget {
  const FarmLocationPickerScreen({super.key});

  @override
  State<FarmLocationPickerScreen> createState() =>
      _FarmLocationPickerScreenState();
}

class _FarmLocationPickerScreenState
    extends State<FarmLocationPickerScreen> {
  LatLng? selectedLocation;

  // Initial map view centered on Tunisia.
  final LatLng initialPosition = const LatLng(34.0, 9.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose farm position'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: initialPosition,
                initialZoom: 6,
                onTap: (tapPosition, point) {
                  setState(() {
                    selectedLocation = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fieldbook',
                ),

                if (selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedLocation!,
                        width: 45,
                        height: 45,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 45,
                        ),
                      ),
                    ],
                  ),

                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selectedLocation != null)
                  Text(
                    'Latitude: ${selectedLocation!.latitude.toStringAsFixed(6)}\n'
                    'Longitude: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                  )
                else
                  const Text(
                    'Tap on the map to choose your farm position.',
                  ),

                const SizedBox(height: 12),

                FilledButton.icon(
                  onPressed: selectedLocation == null
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                            selectedLocation,
                          );
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm position'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
