import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/page_parts.dart';
import '../../../core/widgets/record_form.dart';
import 'admin_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging &&
        _tabController.index == 1 &&
        mounted) {
      ref.invalidate(adminAuditProvider);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final dashboard = ref.watch(adminDashboardProvider);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: PageHeading(
            'Administration.',
            'Users and system activity across Fieldbook.',
            action: _CreateOwnerButton(),
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Audit log'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: () => ref.refresh(adminDashboardProvider.future),
                child: ListView(
                  padding: const EdgeInsets.all(28),
                  children: [
                    dashboard.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (error, _) => ErrorState(
                        error,
                        () => ref.invalidate(adminDashboardProvider),
                      ),
                      data: (data) {
                        final counts = Map<String, dynamic>.from(
                          data['counts'] as Map,
                        );
                        final users = (data['users'] as List)
                            .map(
                              (item) => Map<String, dynamic>.from(item as Map),
                            )
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                final columns = width >= 900
                                    ? 3
                                    : (width >= 560 ? 2 : 1);
                                final itemWidth =
                                    (width - (columns - 1) * 12) / columns;

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
                                      (
                                        'New users (7d)',
                                        counts['new_users_7d'],
                                      ),
                                      (
                                        'Pending recommendations',
                                        counts['pending_recommendations'],
                                      ),
                                      (
                                        'AI recommendations',
                                        counts['ai_recommendations'],
                                      ),
                                      ('Audit events', counts['audit_events']),
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
                                        (user['name'] as String?)?.isNotEmpty ==
                                                true
                                            ? user['name'] as String
                                            : user['username'] as String,
                                      ),
                                      subtitle: Text(
                                        '${user['email']}  •  ${user['role']}',
                                      ),
                                      trailing: Wrap(
                                        spacing: 8,
                                        children: [
                                          SizedBox(
                                            width: 150,
                                            child:
                                                DropdownButtonFormField<String>(
                                                  initialValue:
                                                      user['role'] as String,
                                                  isDense: true,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Role',
                                                      ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: 'admin',
                                                      child: Text('Admin'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'owner',
                                                      child: Text('Farm owner'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'worker',
                                                      child: Text('Worker'),
                                                    ),
                                                  ],
                                                  onChanged: (role) async {
                                                    if (role == null) return;
                                                    await ref
                                                        .read(
                                                          adminRepositoryProvider,
                                                        )
                                                        .updateUser(
                                                          userId:
                                                              user['id'] as int,
                                                          role: role,
                                                        );
                                                    ref.invalidate(
                                                      adminDashboardProvider,
                                                    );
                                                  },
                                                ),
                                          ),
                                          Switch(
                                            value: user['is_active'] == true,
                                            onChanged: (active) async {
                                              await ref
                                                  .read(adminRepositoryProvider)
                                                  .updateUser(
                                                    userId: user['id'] as int,
                                                    isActive: active,
                                                  );
                                              ref.invalidate(
                                                adminDashboardProvider,
                                              );
                                            },
                                          ),
                                        ],
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
              ),
              RefreshIndicator(
                onRefresh: () => ref.refresh(adminAuditProvider.future),
                child: ListView(
                  padding: const EdgeInsets.all(28),
                  children: [
                    Text(
                      'Audit log',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    _AuditFilters(),
                    const SizedBox(height: 12),
                    ref
                        .watch(adminAuditProvider)
                        .when(
                          loading: () => const LinearProgressIndicator(),
                          error: (error, _) => ErrorState(
                            error,
                            () => ref.invalidate(adminAuditProvider),
                          ),
                          data: (events) => events.isEmpty
                              ? const EmptyState(
                                  'No audit events',
                                  'User and system actions will appear here.',
                                )
                              : Card(
                                  child: Column(
                                    children: [
                                      for (final event in events)
                                        ListTile(
                                          dense: true,
                                          leading: const Icon(
                                            Icons.history_outlined,
                                          ),
                                          title: Text(
                                            event['summary'] as String? ??
                                                '${event['action']} ${event['entity']}',
                                          ),
                                          subtitle: Text(
                                            'By ${event['actor']}  ·  ${event['recorded_at']}  ·  ${event['entity']}',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuditFilters extends ConsumerWidget {
  const _AuditFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(auditFiltersProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useColumns = constraints.maxWidth >= 760;
            final fields = [
              _AuditTextFilter(
                label: 'Action',
                hint: 'create, login, accept...',
                value: filters['action'] ?? '',
                onChanged: (value) => _setFilter(ref, 'action', value),
              ),
              _AuditTextFilter(
                label: 'Actor',
                hint: 'Username',
                value: filters['actor'] ?? '',
                onChanged: (value) => _setFilter(ref, 'actor', value),
              ),
              _AuditTextFilter(
                label: 'Entity',
                hint: 'accounts.User, farms.Field...',
                value: filters['entity'] ?? '',
                onChanged: (value) => _setFilter(ref, 'entity', value),
              ),
              _AuditDateFilter(
                label: 'Start date',
                value: filters['start'] ?? '',
                onChanged: (value) => _setFilter(ref, 'start', value),
              ),
              _AuditDateFilter(
                label: 'End date',
                value: filters['end'] ?? '',
                onChanged: (value) => _setFilter(ref, 'end', value),
              ),
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (useColumns)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final field in fields)
                        SizedBox(
                          width: (constraints.maxWidth - 36) / 3,
                          child: field,
                        ),
                    ],
                  )
                else
                  Column(
                    children: [
                      for (var i = 0; i < fields.length; i++) ...[
                        fields[i],
                        if (i != fields.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    ref.read(auditFiltersProvider.notifier).clear();
                    ref.invalidate(adminAuditProvider);
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear filters'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _setFilter(WidgetRef ref, String key, String value) {
    ref.read(auditFiltersProvider.notifier).setFilter(key, value);
    ref.invalidate(adminAuditProvider);
  }
}

class _AuditTextFilter extends StatelessWidget {
  const _AuditTextFilter({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: value,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
    ),
    onChanged: onChanged,
  );
}

class _AuditDateFilter extends StatelessWidget {
  const _AuditDateFilter({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () async {
      final initial = value.isEmpty
          ? DateTime.now()
          : DateTime.tryParse(value) ?? DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        helpText: label,
      );
      if (picked != null) {
        onChanged(picked.toIso8601String().substring(0, 10));
      }
    },
    child: Text(value.isEmpty ? label : '$label: $value'),
  );
}

class _CreateOwnerButton extends ConsumerWidget {
  const _CreateOwnerButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) => FilledButton.icon(
    onPressed: () async {
      try {
        await showRecordForm(
          context,
          title: 'Create farm owner',
          fields: const [
            InputSpec('username', 'Username'),
            InputSpec('email', 'Email'),
            InputSpec('name', 'Full name'),
            InputSpec('password', 'Temporary password'),
          ],
          onSave: (data) async {
            await ref.read(adminRepositoryProvider).createOwner(data);
            ref.invalidate(adminDashboardProvider);
          },
        );
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.toString())));
        }
      }
    },
    icon: const Icon(Icons.person_add_outlined),
    label: const Text('Create owner'),
  );
}
