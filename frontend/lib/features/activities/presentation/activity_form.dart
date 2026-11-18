import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../../../core/widgets/record_form.dart';
import '../../crops/presentation/crop_providers.dart';
import '../domain/activity.dart';
import 'activity_providers.dart';

Future<void> recordWork(BuildContext context, WidgetRef ref) async {
  final kind = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'What happened on the farm?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          for (final kind in activityKinds.entries)
            ListTile(
              title: Text(kind.value),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => Navigator.pop(context, kind.key),
            ),
        ],
      ),
    ),
  );
  if (kind != null && context.mounted) {
    await editActivity(context, ref, kind);
  }
}

Future<void> editActivity(
  BuildContext context,
  WidgetRef ref,
  String kind, [
  ActivityRecord? activity,
]) async {
  try {
    final cycles = (await ref.read(cyclesProvider.future))
        .where((c) => c.canEdit)
        .toList();
    if (!context.mounted) return;
    if (cycles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record a planting before adding work to its history.'),
        ),
      );
      return;
    }
    final units = activityUnits[kind] ?? [];
    await showRecordForm(
      context,
      title:
          '${activity == null ? 'Record' : 'Edit'} ${activityKinds[kind]!.toLowerCase()}',
      fields: [
        if (activity == null)
          InputSpec(
            'cycle',
            'Planting',
            choices: {
              for (final c in cycles)
                '${c.id}': '${c.name} / ${c.fieldName} / ${c.plantingDate}',
            },
          ),
        const InputSpec('date', 'Date', date: true),
        if (kind != 'observation') ...[
          const InputSpec('quantity', 'Quantity', number: true),
          InputSpec(
            'unit',
            'Unit',
            choices: {for (final u in units) u: unitLabels[u]!},
          ),
        ],
        if (kind == 'fertilization' || kind == 'treatment')
          const InputSpec('product', 'Product used'),
        InputSpec(
          'notes',
          kind == 'observation' ? 'What did you observe?' : 'Notes',
          required: kind == 'observation',
          lines: 3,
        ),
      ],
      initial: {
        'date':
            activity?.date ?? DateTime.now().toIso8601String().substring(0, 10),
        'quantity': activity?.quantity?.toString() ?? '',
        'unit': activity?.unit ?? units.firstOrNull ?? '',
        'product': activity?.product ?? '',
        'notes': activity?.notes ?? '',
      },
      onSave: (data) async {
        await ref.read(activityRepositoryProvider).save({
          ...data,
          'kind': kind,
          if (activity == null) 'cycle': int.parse(data['cycle']!),
          if (kind == 'observation') ...{'quantity': null, 'unit': ''},
        }, activity?.id);
        ref.invalidate(activitiesProvider);
      },
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }
}
