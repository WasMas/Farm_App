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
                                              if (farm.canShare)
                                                IconButton(
                                                  tooltip: 'Assign worker',
                                                  onPressed: () => _assignWorker(
                                                    context,
                                                    ref,
                                                    id,
                                                    field.id,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.assignment_ind_outlined,
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
                    onPressed: () => _createWorker(context, ref, id),
                    child: const Text('Create worker'),
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

Future<void> _createWorker(
  BuildContext context,
  WidgetRef ref,
  int farmId,
) async {
  try {
      await showRecordForm(
        context,
        title: 'Create farm worker',
        fields: const [
          InputSpec('username', 'Username'),
          InputSpec('email', 'Email'),
          InputSpec('name', 'Full name'),
          InputSpec('password', 'Temporary password'),
        ],
        onSave: (data) async {
          await ref.read(farmRepositoryProvider).createWorker(farmId, data);
          ref.invalidate(membersProvider(farmId));
        },
      );
  } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
  }
}

Future<void> _assignWorker(
  BuildContext context,
  WidgetRef ref,
  int farmId,
  int fieldId,
) async {
  try {
      final members = await ref.read(membersProvider(farmId).future);
      final workers = members.where((member) => member['role'] == 'worker');
      if (!context.mounted || workers.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create a worker before assigning a field.')),
          );
        }
        return;
      }
      await showRecordForm(
        context,
        title: 'Assign field worker',
        fields: [
          InputSpec(
            'worker',
            'Worker',
            choices: {
              for (final worker in workers)
                '${worker['user']}': worker['username'] as String,
            },
          ),
        ],
        onSave: (data) async {
          await ref.read(farmRepositoryProvider).assignWorker(
            farmId,
            field: fieldId,
            worker: int.parse(data['worker']!),
          );
          ref.invalidate(fieldsProvider(farmId));
        },
      );
  } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
  }
}
