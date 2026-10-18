import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../theme.dart';

const destinations = [
  (path: '/', title: 'The journal', icon: Icons.menu_book_outlined),
  (path: '/farms', title: 'Farms & fields', icon: Icons.landscape_outlined),
  (path: '/crops', title: 'Plantings', icon: Icons.spa_outlined),
  (path: '/activities', title: 'Day’s work', icon: Icons.edit_note_outlined),
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
        /* Local session has still been cleared. */
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
                    style: TextStyle(fontFamily: 'Georgia'),
                  ),
                  actions: [
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
                Container(
                  width: 232,
                  color: FarmColors.olive,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
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
                              fontFamily: 'Georgia',
                              color: FarmColors.paper,
                              fontSize: 30,
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
                          const SizedBox(height: 48),
                          for (var i = 0; i < destinations.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: i == index
                                    ? FarmColors.wheat
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                child: InkWell(
                                  onTap: () => context.go(destinations[i].path),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          destinations[i].icon,
                                          size: 20,
                                          color: i == index
                                              ? FarmColors.olive
                                              : FarmColors.paper,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          destinations[i].title,
                                          style: TextStyle(
                                            color: i == index
                                                ? FarmColors.olive
                                                : FarmColors.paper,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const Spacer(),
                          const Text(
                            'GROW. NOTE. REPEAT.',
                            style: TextStyle(
                              color: Color(0xFFCBD0BC),
                              fontSize: 9,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: Color(0xFF788262)),
                          const SizedBox(height: 16),
                          Text(
                            user?.name.isNotEmpty == true
                                ? user!.name
                                : user?.username ?? '',
                            style: const TextStyle(color: FarmColors.paper),
                          ),
                          Text(
                            user?.role ?? '',
                            style: const TextStyle(
                              color: Color(0xFFCBD0BC),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: logout,
                            icon: const Icon(Icons.logout, size: 16),
                            label: const Text('Sign out'),
                            style: TextButton.styleFrom(
                              foregroundColor: FarmColors.wheat,
                            ),
                          ),
                        ],
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
