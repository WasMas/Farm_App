import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/page_parts.dart';
import '../../../core/widgets/record_form.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/activity.dart';
import 'activity_form.dart';
import 'activity_providers.dart';
import 'activity_tile.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});
  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  String kind = '', search = '';
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          'The day’s work.',
          'Small observations. A lasting record.',
          action: ref.watch(authProvider).asData?.value?.role == 'expert'
              ? null
              : FilledButton.icon(
                  onPressed: () => recordWork(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Record work'),
                ),
        ),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Find a crop, field, product, or note',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => search = v.toLowerCase()),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final entry in {'': 'Everything', ...activityKinds}.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: kind == entry.key,
                    onSelected: (_) => setState(() => kind = entry.key),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ref
              .watch(activitiesProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    ErrorState(e, () => ref.invalidate(activitiesProvider)),
                data: (all) {
                  final list = all
                      .where(
                        (a) =>
                            (kind.isEmpty || a.kind == kind) &&
                            '${a.cropName} ${a.fieldName} ${a.farmName} ${a.product} ${a.notes}'
                                .toLowerCase()
                                .contains(search),
                      )
                      .toList();
                  if (list.isEmpty) {
                    return const SingleChildScrollView(
                      child: EmptyState(
                        'A fresh page',
                        'Record work on a planting, or change your filters.',
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final activity = list[i];
                      return ActivityTile(
                        activity,
                        actions: activity.canEdit
                            ? PopupMenuButton<String>(
                                tooltip: 'Record actions',
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    editActivity(
                                      context,
                                      ref,
                                      activity.kind,
                                      activity,
                                    );
                                  } else {
                                    confirmDelete(
                                      context,
                                      'this record',
                                      () async {
                                        await ref
                                            .read(activityRepositoryProvider)
                                            .delete(activity.id);
                                        ref.invalidate(activitiesProvider);
                                      },
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
        ),
      ],
    ),
  );
}
