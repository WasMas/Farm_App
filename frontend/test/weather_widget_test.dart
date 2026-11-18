import 'package:fieldbook/core/theme.dart';
import 'package:fieldbook/features/weather/domain/weather_report.dart';
import 'package:fieldbook/features/weather/presentation/weather_panel.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('Missing weather shows four placeholders at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: farmTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: WeatherPanel(
                WeatherReport.unavailable('Connect weather.'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('--'), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Zero is a real weather value', (tester) async {
    final report = WeatherReport.fromJson({
      'status': 'ok',
      'message': 'Current conditions',
      'current': {
        'temperature': 0,
        'humidity': 0,
        'precipitation': 0,
        'wind': 0,
      },
      'forecast': [],
      'cached': false,
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: farmTheme(),
        home: Scaffold(
          body: SingleChildScrollView(child: WeatherPanel(report)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0.0'), findsNWidgets(4));
    expect(find.text('--'), findsNothing);
  });
}
