import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../theme.dart';
import '../theme_mode.dart';

const destinations = [
  (path: '/', title: 'The journal', icon: Icons.menu_book_outlined),
  (path: '/farms', title: 'Farms & fields', icon: Icons.landscape_outlined),
  (path: '/crops', title: 'Plantings', icon: Icons.spa_outlined),
  (path: '/activities', title: 'Day’s work', icon: Icons.edit_note_outlined),
  (path: '/weather', title: 'Weather', icon: Icons.wb_sunny_outlined),
];

class FarmShell extends ConsumerWidget {
  const FarmShell({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final index = destinations.indexWhere(
      (d) => d.path == '/' ? path == '/' : path.startsWith(d.path),
    );
    final user = ref.watch(authProvider).asData?.value;
    Future<void> logout() async {
      try {
        await ref.read(authProvider.notifier).logout();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Signed out on this device. The server could not be reached.',
              ),
            ),
          );
        }
      }
    }

    return LayoutBuilder(
      builder: (context, size) {
        final desktop = size.maxWidth >= 900;
        return Scaffold(
          appBar: desktop
              ? null
              : AppBar(
                  title: const Text(
                    'Fieldbook',
                    style: TextStyle(fontFamily: 'Lora'),
                  ),
                  actions: [
                    const ThemeMenu(),
                    IconButton(
                      tooltip: 'Sign out',
                      onPressed: logout,
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
          bottomNavigationBar: desktop
              ? null
              : NavigationBar(
                  selectedIndex: index < 0 ? 0 : index,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  onDestinationSelected: (i) =>
                      context.go(destinations[i].path),
                  destinations: [
                    for (final d in destinations)
                      NavigationDestination(icon: Icon(d.icon), label: d.title),
                  ],
                ),
          body: Row(
            children: [
              if (desktop)
                SizedBox(
                  width: 232,
                  child: ColoredBox(
                    color: FarmColors.olive,
                    child: SafeArea(
                      child: LayoutBuilder(
                        builder: (context, bounds) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: bounds.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  32,
                                  24,
                                  24,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.grass,
                                      color: FarmColors.wheat,
                                      size: 36,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Fieldbook',
                                      style: TextStyle(
                                        fontFamily: 'Lora',
                                        color: FarmColors.paper,
                                        fontSize: 29,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'THE WORKING FARM JOURNAL',
                                      style: TextStyle(
                                        color: Color(0xFFCBD0BC),
                                        fontSize: 9,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    for (
                                      var i = 0;
                                      i < destinations.length;
                                      i++
                                    )
                                      _NavItem(i, selected: i == index),
                                    const SizedBox(height: 32),
                                    const Spacer(),
                                    const Text(
                                      'GROW. NOTE. REPEAT.',
                                      style: TextStyle(
                                        color: Color(0xFFCBD0BC),
                                        fontSize: 9,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Divider(color: Color(0xFF788262)),
                                    const SizedBox(height: 16),
                                    Text(
                                      user?.name.isNotEmpty == true
                                          ? user!.name
                                          : user?.username ?? '',
                                      style: const TextStyle(
                                        color: FarmColors.paper,
                                      ),
                                    ),
                                    Text(
                                      user?.role ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFFCBD0BC),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: logout,
                                            icon: const Icon(
                                              Icons.logout,
                                              size: 16,
                                            ),
                                            label: const Text('Sign out'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: FarmColors.wheat,
                                            ),
                                          ),
                                        ),
                                        const ThemeMenu(
                                          color: FarmColors.wheat,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(child: SafeArea(child: child)),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(this.index, {required this.selected});
  final int index;
  final bool selected;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: selected ? FarmColors.wheat : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => context.go(destinations[index].path),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          child: Row(
            children: [
              Icon(
                destinations[index].icon,
                size: 20,
                color: selected ? FarmColors.olive : FarmColors.paper,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destinations[index].title,
                  style: TextStyle(
                    color: selected ? FarmColors.olive : FarmColors.paper,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
