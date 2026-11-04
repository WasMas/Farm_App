import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/page_parts.dart';
import '../../../core/widgets/record_form.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/crop_cycle.dart';
import 'crop_form.dart';
import 'crop_providers.dart';

class CropsScreen extends ConsumerStatefulWidget {
  const CropsScreen({super.key});
  @override
  ConsumerState<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends ConsumerState<CropsScreen> {
  String status = 'active';
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      PageHeading(
        'Seasons of growth.',
        'A new planting, a fresh page. Past seasons stay in your journal.',
        action: ref.watch(authProvider).asData?.value?.role == 'expert'
            ? null
            : FilledButton.icon(
                onPressed: () => editCycle(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New planting'),
              ),
      ),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final s in {
            'active': 'Growing now',
            'completed': 'Past seasons',
          }.entries)
            ChoiceChip(
              label: Text(s.value),
              selected: status == s.key,
              onSelected: (_) => setState(() => status = s.key),
            ),
          if (ref.watch(authProvider).asData?.value?.isAdmin == true)
            TextButton(
              onPressed: () => context.go('/crops/types'),
              child: const Text('Manage crop types'),
            ),
        ],
      ),
      const SizedBox(height: 24),
      ref
          .watch(cyclesProvider)
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) =>
                ErrorState(e, () => ref.invalidate(cyclesProvider)),
            data: (all) {
              final cycles = all.where((c) => c.status == status).toList();
              if (cycles.isEmpty) {
                return EmptyState(
                  status == 'active'
                      ? 'The next season starts here'
                      : 'A history worth keeping',
                  status == 'active'
                      ? 'Choose a field and record your first planting.'
                      : 'Completed planting cycles will appear here.',
                );
              }
              return Column(
                children: [
                  for (final c in cycles)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.variety.isEmpty
                                          ? c.name
                                          : '${c.name} · ${c.variety}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                  ),
                                  if (c.canEdit) ...[
                                    IconButton(
                                      tooltip: 'Edit planting',
                                      onPressed: () =>
                                          editCycle(context, ref, c),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete planting',
                                      onPressed: () => confirmDelete(
                                        context,
                                        'this planting',
                                        () async {
                                          await ref
                                              .read(cropRepositoryProvider)
                                              .delete(c.id);
                                          ref.invalidate(cyclesProvider);
                                        },
                                      ),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ],
                              ),
                              Text('${c.farmName} / ${c.fieldName}'),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 24,
                                runSpacing: 12,
                                children: [
                                  Text('${c.area.toStringAsFixed(2)} ha'),
                                  Text('Planted ${c.plantingDate}'),
                                  Text(stages[c.stage] ?? c.stage),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value:
                                    (stages.keys.toList().indexOf(c.stage) +
                                        1) /
                                    stages.length,
                                minHeight: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
    ],
  );
}
