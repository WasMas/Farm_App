import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesProvider = FutureProvider(
  (ref) => SharedPreferences.getInstance(),
);
final themeModeProvider = AsyncNotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

class ThemeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final saved = (await ref.watch(preferencesProvider.future))
        .getString('theme');
    return ThemeMode.values.where((mode) => mode.name == saved).firstOrNull ??
        ThemeMode.system;
  }

  Future<void> choose(ThemeMode mode) async {
    final prefs = await ref.read(preferencesProvider.future);
    await prefs.setString('theme', mode.name);
    state = AsyncData(mode);
  }
}

class ThemeMenu extends ConsumerWidget {
  const ThemeMenu({super.key, this.color});
  final Color? color;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PopupMenuButton<ThemeMode>(
        tooltip: 'Appearance',
        icon: Icon(Icons.contrast, color: color),
        initialValue: ref.watch(themeModeProvider).asData?.value,
        onSelected: (mode) async {
          try {
            await ref.read(themeModeProvider.notifier).choose(mode);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not save the appearance setting.'),
                ),
              );
            }
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: ThemeMode.system, child: Text('Follow device')),
          PopupMenuItem(value: ThemeMode.light, child: Text('Warm daylight')),
          PopupMenuItem(value: ThemeMode.dark, child: Text('After sunset')),
        ],
      );
}
