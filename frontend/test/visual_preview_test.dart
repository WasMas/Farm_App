import 'dart:io';
import 'dart:ui' as ui;

import 'package:fieldbook/app.dart';
import 'package:fieldbook/core/session_store.dart';
import 'package:fieldbook/core/theme_mode.dart';
import 'package:fieldbook/features/auth/presentation/auth_provider.dart';
import 'package:fieldbook/features/dashboard/domain/farm_summary.dart';
import 'package:fieldbook/features/dashboard/presentation/dashboard_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_tokens.dart';
import 'support/signed_in_controller.dart';

void main() {
  for (final scene in [
    (size: const Size(390, 1000), dark: false),
    (size: const Size(1440, 1000), dark: false),
    (size: const Size(390, 1000), dark: true),
  ]) {
    testWidgets('Render local theme preview at $scene', (tester) async {
      final size = scene.size;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        for (final font in ['Lora', 'DMSans']) {
          await (FontLoader(
            font,
          )..addFont(rootBundle.load('assets/fonts/$font.ttf'))).load();
        }
      });
      final summary = FarmSummary.fromJson({
        'farms': 1,
        'fields': 3,
        'active_cycles': 2,
        'activities_week': 6,
        'total_area': '12.5',
        'irrigation_m3_week': '7.5',
        'harvest_kg': '450',
        'harvest_items': 0,
        'plantings': [
          {
            'id': 1,
            'field': 1,
            'crop_type': 1,
            'crop_name': 'Tomato',
            'field_name': 'North terrace',
            'farm_name': 'Les Oliviers',
            'variety': 'Cherry',
            'planting_date': '2026-10-01',
            'current_stage': 'flowering',
            'status': 'active',
            'area': '1.2',
            'can_edit': true,
          },
        ],
        'recent_activities': [
          {
            'id': 1,
            'cycle': 1,
            'kind': 'irrigation',
            'date': '2026-10-18',
            'quantity': '7.5',
            'unit': 'm3',
            'product': '',
            'notes': 'A slow watering along the north terrace.',
            'crop_name': 'Tomato',
            'field_name': 'North terrace',
            'farm_name': 'Les Oliviers',
            'author_name': 'Amina',
            'can_edit': true,
          },
        ],
      });
      final capture = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStoreProvider.overrideWithValue(MemoryTokens()),
            themeModeProvider.overrideWith(
              () => PreviewTheme(scene.dark ? ThemeMode.dark : ThemeMode.light),
            ),
            authProvider.overrideWith(SignedInController.new),
            dashboardProvider.overrideWith((ref) async => summary),
          ],
          child: RepaintBoundary(key: capture, child: const FieldbookApp()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (capture.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          '../.local/previews/${size.width < 900 ? 'phone' : 'desktop'}${scene.dark ? '_dark' : ''}.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }, skip: !const bool.fromEnvironment('CAPTURE_PREVIEWS'));
  }
}

class PreviewTheme extends ThemeController {
  PreviewTheme(this.mode);
  final ThemeMode mode;
  @override
  Future<ThemeMode> build() async => mode;
}
