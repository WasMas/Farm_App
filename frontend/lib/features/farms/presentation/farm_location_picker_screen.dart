import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FarmLocationPickerScreen extends StatelessWidget {
  const FarmLocationPickerScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose farm position')),
    body: FarmLocationPickerPanel(
      onSelected: (location, _) => Navigator.pop(context, location),
    ),
  );
}

class FarmLocationPickerPanel extends StatefulWidget {
  const FarmLocationPickerPanel({super.key, required this.onSelected});

  final FutureOr<void> Function(LatLng location, String displayName) onSelected;

  @override
  State<FarmLocationPickerPanel> createState() =>
      _FarmLocationPickerPanelState();
}

class _FarmLocationPickerPanelState extends State<FarmLocationPickerPanel> {
  LatLng? selectedLocation;
  bool loading = false;
  String? error;

  final LatLng initialPosition = const LatLng(34.0, 9.0);

  Future<void> confirmSelection() async {
    final location = selectedLocation;
    if (location == null || loading) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await Dio().get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': location.latitude,
          'lon': location.longitude,
          'format': 'jsonv2',
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(
          headers: {'User-Agent': 'Fieldbook/0.1 (farm location picker)'},
        ),
      );
      final displayName = response.data?['display_name'];

      if (displayName is! String || displayName.trim().isEmpty) {
        throw StateError('The selected location has no readable address.');
      }

      await widget.onSelected(location, displayName);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Could not find the location name. You can enter it manually.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: initialPosition,
            initialZoom: 6,
            onTap: (tapPosition, point) {
              setState(() {
                selectedLocation = point;
                error = null;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                TextSourceAttribution('© OpenStreetMap contributors'),
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
              const Text('Tap on the map to choose your farm position.'),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: selectedLocation == null || loading
                  ? null
                  : confirmSelection,
              icon: const Icon(Icons.check),
              label: Text(loading ? 'Finding location…' : 'Confirm position'),
            ),
          ],
        ),
      ),
    ],
  );
}
