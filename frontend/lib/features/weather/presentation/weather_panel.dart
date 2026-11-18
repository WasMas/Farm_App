import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../domain/weather_report.dart';

class WeatherPanel extends StatelessWidget {
  const WeatherPanel(this.report, {super.key});
  final WeatherReport report;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: FarmColors.olive,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.wb_sunny_outlined,
              color: FarmColors.wheat,
              size: 42,
            ),
            const SizedBox(height: 24),
            Text(
              report.status == 'ok'
                  ? 'The sky over your fields.'
                  : 'Waiting on the sky.',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: FarmColors.paper),
            ),
            const SizedBox(height: 12),
            Text(
              report.message,
              style: const TextStyle(color: Color(0xFFDFE4D2)),
            ),
            if (report.observedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Conditions at ${DateFormat('dd MMM, HH:mm').format(DateTime.parse(report.observedAt!).toLocal())}${report.cached ? ' · cached' : ''}',
                  style: const TextStyle(color: FarmColors.wheat, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      LayoutBuilder(
        builder: (context, size) => GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: size.maxWidth >= 800 ? 4 : 2,
            mainAxisExtent: 160,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          children: [
            for (final metric in [
              (
                keyName: 'temperature',
                title: 'Temperature',
                unit: '°C',
                icon: Icons.thermostat_outlined,
              ),
              (
                keyName: 'humidity',
                title: 'Humidity',
                unit: '%',
                icon: Icons.water_drop_outlined,
              ),
              (
                keyName: 'precipitation',
                title: 'Precipitation',
                unit: 'mm',
                icon: Icons.grain,
              ),
              (keyName: 'wind', title: 'Wind', unit: 'km/h', icon: Icons.air),
            ])
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(metric.icon, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              metric.title,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        report.value(metric.keyName),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        metric.unit,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      if (report.forecast.isNotEmpty) ...[
        const SizedBox(height: 32),
        Text(
          'The days ahead',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        for (final day in report.forecast)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              DateFormat('EEE, dd MMM')
                  .format(DateTime.parse(day['date'] as String)),
            ),
            subtitle: Text('Rain: ${day['rain'] ?? '--'} mm'),
            trailing: Text('${day['low'] ?? '--'}° / ${day['high'] ?? '--'}°'),
          ),
      ],
      const SizedBox(height: 24),
      const SelectableText(
        'Weather data: Open-Meteo · open-meteo.com · CC BY 4.0',
        style: TextStyle(fontSize: 11),
      ),
    ],
  );
}
