import 'package:fieldbook/app.dart';
import 'package:fieldbook/core/session_store.dart';
import 'package:fieldbook/core/theme_mode.dart';
import 'package:fieldbook/features/auth/presentation/auth_provider.dart';
import 'package:fieldbook/features/dashboard/domain/farm_summary.dart';
import 'package:fieldbook/features/dashboard/presentation/dashboard_provider.dart';
import 'package:fieldbook/features/farms/presentation/farm_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';
import 'support/signed_in_controller.dart';

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(800, 600),
    const Size(1440, 600),
  ]) {
    testWidgets('Full navigation and logout at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final summary = FarmSummary.fromJson({
        'farms': 0,
        'fields': 0,
        'active_cycles': 0,
        'activities_week': 0,
        'total_area': 0,
        'irrigation_m3_week': 0,
        'harvest_kg': 0,
        'harvest_items': 0,
        'plantings': [],
        'recent_activities': [],
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStoreProvider.overrideWithValue(MemoryTokens()),
            authProvider.overrideWith(SignedInController.new),
            dashboardProvider.overrideWith((ref) async => summary),
            farmsProvider.overrideWith((ref) async => []),
          ],
          child: const FieldbookApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A good day to grow.'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.landscape_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Room to grow'), findsOneWidget);
      final signOut = find.byTooltip('Sign out');
      if (signOut.evaluate().isNotEmpty) {
        await tester.tap(signOut);
      } else {
        await tester.ensureVisible(find.text('Sign out'));
        await tester.tap(find.text('Sign out'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Back to the land.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test('Theme selection persists across provider containers', () async {
    final first = ProviderContainer();
    addTearDown(first.dispose);
    await first.read(themeModeProvider.future);
    await first.read(themeModeProvider.notifier).choose(ThemeMode.dark);
    final second = ProviderContainer();
    addTearDown(second.dispose);
    expect(await second.read(themeModeProvider.future), ThemeMode.dark);
  });
}
