import 'package:fieldbook/core/session_store.dart';
import 'package:fieldbook/core/theme.dart';
import 'package:fieldbook/features/farms/domain/farm.dart';
import 'package:fieldbook/features/farms/presentation/farm_providers.dart';
import 'package:fieldbook/features/farms/presentation/farms_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('Farm list renders without overflow at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final farm = Farm.fromJson({
        'id': 1,
        'name': 'The olive grove',
        'location': 'Tunis',
        'total_area': '12.50',
        'field_count': 2,
        'can_edit': true,
        'can_share': true,
        'can_work': true,
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStoreProvider.overrideWithValue(MemoryTokens()),
            farmsProvider.overrideWith((ref) async => [farm]),
          ],
          child: MaterialApp(
            theme: farmTheme(),
            home: const Scaffold(body: FarmsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('The olive grove'), findsOneWidget);
      expect(find.text('12.50 ha   /   2 fields'), findsOneWidget);
      await tester.tap(find.text('Add farm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter farm name'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
