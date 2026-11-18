

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../farms/domain/farm.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.farms,
  });

  final List<Farm> farms;

  @override
  State<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState
    extends State<LocationPickerScreen> {
  Farm? selectedFarm;

  // Only farms with valid saved coordinates can appear on the map.
  List<Farm> get locatedFarms {
    return widget.farms.where((farm) {
      final lat = double.tryParse(farm.latitude ?? '');
      final lon = double.tryParse(farm.longitude ?? '');

      return lat != null &&
          lon != null &&
          lat >= -90 &&
          lat <= 90 &&
          lon >= -180 &&
          lon <= 180;
    }).toList();
  }

  LatLng positionOf(Farm farm) {
    return LatLng(
      double.parse(farm.latitude!),
      double.parse(farm.longitude!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farms = locatedFarms;

    final initialPosition = farms.isNotEmpty
        ? positionOf(farms.first)
        : const LatLng(34.0, 9.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a farm'),
      ),
      body: Column(
        children: [
          Expanded(
            child: farms.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No farms with saved coordinates were found.\n\n'
                        'Add latitude and longitude to a farm '
                        'to display it on the map.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: initialPosition,
                      initialZoom: 8,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.fieldbook',
                      ),
                      MarkerLayer(
                        markers: farms.map((farm) {
                          final isSelected =
                              selectedFarm?.id == farm.id;

                          return Marker(
                            point: positionOf(farm),
                            width: 150,
                            height: 65,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedFarm = farm;
                                });
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_pin,
                                    size: 38,
                                    color: isSelected
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.green
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      farm.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
                if (selectedFarm != null) ...[
                  Text(
                    'Selected farm: ${selectedFarm!.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(selectedFarm!.location),
                ] else
                  const Text(
                    'Tap a farm marker on the map to select it.',
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: selectedFarm == null
                      ? null
                      : () {
                          Navigator.pop(context, selectedFarm);
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Select this farm'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
