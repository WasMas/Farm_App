import 'package:fieldbook/core/session_store.dart';
import 'package:fieldbook/core/theme.dart';
import 'package:fieldbook/features/crops/domain/crop_cycle.dart';
import 'package:fieldbook/features/crops/presentation/crop_providers.dart';
import 'package:fieldbook/features/crops/presentation/crops_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('Plantings render and filter at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cycle = CropCycle.fromJson({
        'id': 1,
        'field': 1,
        'crop_type': 1,
        'crop_name': 'Tomato',
        'field_name': 'North',
        'farm_name': 'Olive grove',
        'variety': 'Cherry',
        'planting_date': '2026-10-01',
        'end_date': null,
        'current_stage': 'flowering',
        'status': 'active',
        'area': '1.20',
        'can_edit': true,
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStoreProvider.overrideWithValue(MemoryTokens()),
            cyclesProvider.overrideWith((ref) async => [cycle]),
          ],
          child: MaterialApp(
            theme: farmTheme(),
            home: const Scaffold(body: CropsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tomato · Cherry'), findsOneWidget);
      await tester.tap(find.text('Past seasons'));
      await tester.pumpAndSettle();
      expect(find.text('A history worth keeping'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
