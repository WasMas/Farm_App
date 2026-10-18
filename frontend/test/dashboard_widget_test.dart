import 'package:fieldbook/core/session_store.dart';
import 'package:fieldbook/core/theme.dart';
import 'package:fieldbook/features/dashboard/domain/farm_summary.dart';
import 'package:fieldbook/features/dashboard/presentation/dashboard_provider.dart';
import 'package:fieldbook/features/dashboard/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('Dashboard renders real summary values at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final summary = FarmSummary.fromJson({
        'farms': 1,
        'fields': 2,
        'active_cycles': 3,
        'activities_week': 4,
        'total_area': '12.5',
        'irrigation_m3_week': '7.5',
        'harvest_kg': '2050',
        'harvest_items': 0,
        'plantings': [],
        'recent_activities': [],
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStoreProvider.overrideWithValue(MemoryTokens()),
            dashboardProvider.overrideWith((ref) async => summary),
          ],
          child: MaterialApp(
            theme: farmTheme(),
            home: const Scaffold(body: HomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('12.50'), findsOneWidget);
      expect(find.text('2050.0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
