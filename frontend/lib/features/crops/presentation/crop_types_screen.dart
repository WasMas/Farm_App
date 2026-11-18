import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/page_parts.dart';
import '../../../core/widgets/record_form.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/crop_cycle.dart';
import 'crop_providers.dart';

class CropTypesScreen extends ConsumerWidget {
  const CropTypesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(authProvider).asData?.value?.isAdmin == true;
    Future<void> edit([CropType? type]) => showRecordForm(
      context,
      title: type == null ? 'Add a crop type' : 'Edit crop type',
      fields: const [
        InputSpec('name', 'Crop name'),
        InputSpec('description', 'Notes', required: false, lines: 3),
      ],
      initial: {
        'name': type?.name ?? '',
        'description': type?.description ?? '',
      },
      onSave: (data) async {
        await ref.read(cropRepositoryProvider).saveType(data, type?.id);
        ref.invalidate(cropTypesProvider);
      },
    );
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        PageHeading(
          'The crop catalogue.',
          'Shared reference names for a consistent farm journal.',
          action: admin
              ? FilledButton(
                  onPressed: edit,
                  child: const Text('Add crop type'),
                )
              : null,
        ),
        ref
            .watch(cropTypesProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) =>
                  ErrorState(e, () => ref.invalidate(cropTypesProvider)),
              data: (types) => Column(
                children: [
                  for (final type in types)
                    ListTile(
                      title: Text(type.name),
                      subtitle: type.description.isEmpty
                          ? null
                          : Text(type.description),
                      trailing: admin
                          ? Wrap(
                              children: [
                                IconButton(
                                  tooltip: 'Edit crop type',
                                  onPressed: () => edit(type),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete crop type',
                                  onPressed: () => confirmDelete(
                                    context,
                                    type.name,
                                    () async {
                                      await ref
                                          .read(cropRepositoryProvider)
                                          .deleteType(type.id);
                                      ref.invalidate(cropTypesProvider);
                                    },
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            )
                          : null,
                    ),
                ],
              ),
            ),
      ],
    );
  }
}
