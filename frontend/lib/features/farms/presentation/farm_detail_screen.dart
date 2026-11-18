import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/page_parts.dart';
import '../../../core/widgets/record_form.dart';
import 'farm_forms.dart';
import 'farm_providers.dart';

class FarmDetailScreen extends ConsumerWidget {
  const FarmDetailScreen(this.id, {super.key});
  final int id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(farmProvider(id))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(e, () => ref.invalidate(farmProvider(id))),
        data: (farm) => ListView(
          padding: const EdgeInsets.all(28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/farms'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('All farms'),
              ),
            ),
            const SizedBox(height: 12),
            PageHeading(
              farm.name,
              '${farm.location}  /  ${farm.area.toStringAsFixed(2)} ha',
              action: farm.canEdit
                  ? OutlinedButton(
                      onPressed: () => editFarm(context, ref, farm),
                      child: const Text('Edit farm'),
                    )
                  : null,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fields',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (farm.canWork)
                  TextButton.icon(
                    onPressed: () => editField(context, ref, id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add field'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ref
                .watch(fieldsProvider(id))
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) =>
                      ErrorState(e, () => ref.invalidate(fieldsProvider(id))),
                  data: (fields) => fields.isEmpty
                      ? const EmptyState(
                          'An open canvas',
                          'Add a field to start planning your next planting.',
                        )
                      : Column(
                          children: [
                            for (final field in fields)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: const Icon(Icons.crop_square),
                                    title: Text(field.name),
                                    subtitle: Text(
                                      '${field.area.toStringAsFixed(2)} ha  ·  ${field.soil} soil',
                                    ),
                                    trailing: field.canEdit
                                        ? Wrap(
                                            children: [
                                              IconButton(
                                                tooltip: 'Edit field',
                                                onPressed: () => editField(
                                                  context,
                                                  ref,
                                                  id,
                                                  field,
                                                ),
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Delete field',
                                                onPressed: () => confirmDelete(
                                                  context,
                                                  field.name,
                                                  () async {
                                                    await ref
                                                        .read(
                                                          farmRepositoryProvider,
                                                        )
                                                        .deleteField(field.id);
                                                    ref.invalidate(
                                                      fieldsProvider,
                                                    );
                                                    ref.invalidate(
                                                      farmsProvider,
                                                    );
                                                    ref.invalidate(
                                                      farmProvider(id),
                                                    );
                                                  },
                                                ),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'People on this farm',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (farm.canShare)
                  TextButton(
                    onPressed: () => showRecordForm(
                      context,
                      title: 'Share farm access',
                      fields: const [
                        InputSpec('username', 'Existing username'),
                        InputSpec(
                          'role',
                          'Access',
                          choices: {
                            'manager': 'Manager — manage farm and records',
                            'worker': 'Worker — manage field records',
                            'viewer': 'Viewer — read only',
                          },
                        ),
                      ],
                      onSave: (data) async {
                        await ref
                            .read(farmRepositoryProvider)
                            .share(id, data['username']!, data['role']!);
                        ref.invalidate(membersProvider(id));
                      },
                    ),
                    child: const Text('Add person'),
                  ),
              ],
            ),
            ref
                .watch(membersProvider(id))
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) =>
                      ErrorState(e, () => ref.invalidate(membersProvider(id))),
                  data: (members) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('The farm owner always has full access.'),
                      ),
                      for (final m in members)
                        ListTile(
                          title: Text(m['username'] as String),
                          subtitle: Text(m['role'] as String),
                          trailing: farm.canShare
                              ? IconButton(
                                  tooltip: 'Remove access',
                                  onPressed: () => confirmDelete(
                                    context,
                                    'this access',
                                    () async {
                                      await ref
                                          .read(farmRepositoryProvider)
                                          .unshare(id, m['user'] as int);
                                      ref.invalidate(membersProvider(id));
                                    },
                                  ),
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                  ),
                                )
                              : null,
                        ),
                    ],
                  ),
                ),
            if (farm.canShare)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => confirmDelete(context, farm.name, () async {
                    await ref.read(farmRepositoryProvider).deleteFarm(id);
                    ref.invalidate(farmsProvider);
                    if (context.mounted) context.go('/farms');
                  }),
                  child: Text(
                    'Delete farm',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
