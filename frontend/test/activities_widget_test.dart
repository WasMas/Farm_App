import 'package:fieldbook/core/session_store.dart';
import 'package:fieldbook/core/theme.dart';
import 'package:fieldbook/features/activities/domain/activity.dart';
import 'package:fieldbook/features/activities/presentation/activity_providers.dart';
import 'package:fieldbook/features/activities/presentation/activities_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('Activity history renders and searches at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final activity = ActivityRecord.fromJson({
        'id': 1,
        'cycle': 1,
        'kind': 'irrigation',
        'date': '2026-10-18',
        'quantity': '12.5',
        'unit': 'm3',
        'product': '',
        'notes': 'North irrigation line',
        'crop_name': 'Tomato',
        'field_name': 'North',
        'farm_name': 'Grove',
        'author_name': 'Farmer',
        'can_edit': true,
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStoreProvider.overrideWithValue(MemoryTokens()),
            activitiesProvider.overrideWith((ref) async => [activity]),
          ],
          child: MaterialApp(
            theme: farmTheme(),
            home: const Scaffold(body: ActivitiesScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('12.5 m³'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'unmatched');
      await tester.pumpAndSettle();
      expect(find.text('A fresh page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
