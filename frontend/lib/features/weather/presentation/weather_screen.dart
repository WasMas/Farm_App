import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/page_parts.dart';
import '../../../core/widgets/record_form.dart';
import '../../farms/presentation/farm_providers.dart';
import '../domain/weather_report.dart';
import 'weather_panel.dart';
import 'weather_providers.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});
  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  int? selectedFarm;
  int refresh = 0;
  Future<void> configure() async {
    try {
      final config = await ref.read(weatherConfigProvider.future);
      if (!mounted) return;
      await showRecordForm(
        context,
        title: 'Weather connection',
        fields: [
          const InputSpec(
            'enabled',
            'Weather connection',
            choices: {'true': 'Connected', 'false': 'Off'},
          ),
          const InputSpec(
            'mode',
            'Open-Meteo service',
            choices: {
              'public': 'Public API — no key needed',
              'customer': 'Customer API — key required',
            },
          ),
          InputSpec(
            'key',
            'Customer API key',
            secret: true,
            required: false,
            help: config.hasKey
                ? 'A key is saved. Leave blank to keep it.'
                : 'Optional. Only needed for the customer service.',
          ),
          const InputSpec(
            'clear_key',
            'Saved key',
            choices: {'false': 'Keep saved key', 'true': 'Remove saved key'},
          ),
        ],
        initial: {
          'enabled': '${config.enabled}',
          'mode': config.mode,
          'clear_key': 'false',
        },
        onSave: (data) async {
          await ref
              .read(weatherRepositoryProvider)
              .configure(
                enabled: data['enabled'] == 'true',
                mode: data['mode']!,
                key: data['key']!,
                clearKey: data['clear_key'] == 'true',
              );
          ref.invalidate(weatherConfigProvider);
          ref.invalidate(weatherProvider);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not load weather settings. Check your connection.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      PageHeading(
        'A look at the sky.',
        'Conditions for the land you are tending.',
        action: OutlinedButton.icon(
          onPressed: configure,
          icon: const Icon(Icons.tune),
          label: const Text('Weather settings'),
        ),
      ),
      ref
          .watch(farmsProvider)
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Column(
              children: [
                ErrorState(e, () => ref.invalidate(farmsProvider)),
                WeatherPanel(
                  WeatherReport.unavailable(
                    'Weather is unavailable until your farms can be loaded.',
                  ),
                ),
              ],
            ),
            data: (farms) {
              if (farms.isEmpty) {
                return Column(
                  children: [
                    const EmptyState(
                      'Weather needs a place',
                      'Add a farm and its coordinates to get started.',
                    ),
                    WeatherPanel(
                      WeatherReport.unavailable('No farm selected.'),
                    ),
                  ],
                );
              }
              final id = farms.any((f) => f.id == selectedFarm)
                  ? selectedFarm!
                  : farms.first.id;
              final weather = ref.watch(
                weatherProvider((farm: id, refresh: refresh)),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: ValueKey(id),
                          initialValue: id,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Farm'),
                          items: farms
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f.id,
                                  child: Text(
                                    f.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() {
                            selectedFarm = value;
                            refresh = 0;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Refresh weather',
                        onPressed: weather.isLoading
                            ? null
                            : () => setState(() => refresh++),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (weather.isLoading) const LinearProgressIndicator(),
                  WeatherPanel(
                    weather.when(
                      data: (value) => value,
                      error: (_, _) => WeatherReport.unavailable(
                        'Weather could not be loaded. Try refreshing.',
                      ),
                      loading: () =>
                          WeatherReport.unavailable('Checking conditions…'),
                    ),
                  ),
                ],
              );
            },
          ),
    ],
  );
}
