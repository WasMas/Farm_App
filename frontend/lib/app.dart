import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'core/router.dart';
import 'core/theme_mode.dart';

class FieldbookApp extends ConsumerWidget {
  const FieldbookApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Fieldbook',
    debugShowCheckedModeBanner: false,
    theme: farmTheme(),
    darkTheme: farmTheme(true),
    themeMode: ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system,
    routerConfig: ref.watch(routerProvider),
  );
}
