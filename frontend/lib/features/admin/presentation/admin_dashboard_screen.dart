import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/page_parts.dart';
import 'admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminDashboardProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const PageHeading(
            'Administration.',
            'Users and system activity across Fieldbook.',
          ),
          dashboard.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) =>
                ErrorState(error, () => ref.invalidate(adminDashboardProvider)),
            data: (data) {
              final counts = Map<String, dynamic>.from(data['counts'] as Map);
              final users = (data['users'] as List)
                  .map((item) => Map<String, dynamic>.from(item as Map))
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = width >= 900 ? 3 : (width >= 560 ? 2 : 1);
                      final itemWidth = (width - (columns - 1) * 12) / columns;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final entry in [
                            ('Users', counts['users']),
                            ('Farms', counts['farms']),
                            ('Fields', counts['fields']),
                            ('Active crops', counts['active_crops']),
                            ('Activities', counts['activities']),
                            ('New users (7d)', counts['new_users_7d']),
                          ])
                            SizedBox(
                              width: itemWidth,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry.$2}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(entry.$1),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Recent users',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        for (final user in users) ...[
                          ListTile(
                            title: Text(
                              (user['name'] as String?)?.isNotEmpty == true
                                  ? user['name'] as String
                                  : user['username'] as String,
                            ),
                            subtitle: Text(
                              '${user['email']}  •  ${user['role']}',
                            ),
                            trailing: SizedBox(
                              width: 150,
                              child: DropdownButtonFormField<String>(
                                initialValue: user['role'] as String,
                                isDense: true,
                                decoration: const InputDecoration(
                                  labelText: 'Role',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'admin',
                                    child: Text('Admin'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'farmer',
                                    child: Text('Farmer'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'expert',
                                    child: Text('Expert'),
                                  ),
                                ],
                                onChanged: (role) async {
                                  if (role == null) return;
                                  await ref
                                      .read(adminRepositoryProvider)
                                      .updateUser(
                                        userId: user['id'] as int,
                                        role: role,
                                      );
                                  ref.invalidate(adminDashboardProvider);
                                },
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
