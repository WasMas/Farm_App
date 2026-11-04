import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../../../core/widgets/record_form.dart';
import '../../farms/presentation/farm_providers.dart';
import '../domain/crop_cycle.dart';
import 'crop_providers.dart';

Future<void> editCycle(
  BuildContext context,
  WidgetRef ref, [
  CropCycle? cycle,
]) async {
  try {
    final fields = (await ref.read(fieldsProvider(null).future))
        .where((f) => f.canEdit)
        .toList();
    final types = await ref.read(cropTypesProvider.future);
    if (!context.mounted) return;
    if (fields.isEmpty || types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add an editable field and a crop type before planting.',
          ),
        ),
      );
      return;
    }
    await showRecordForm(
      context,
      title: cycle == null ? 'Begin a growing season' : 'Tend this planting',
      fields: [
        if (cycle == null) ...[
          InputSpec(
            'field',
            'Field',
            choices: {
              for (final f in fields) '${f.id}': '${f.farmName} / ${f.name}',
            },
          ),
          InputSpec(
            'crop_type',
            'Crop',
            choices: {for (final t in types) '${t.id}': t.name},
          ),
        ],
        const InputSpec('variety', 'Variety', required: false),
        const InputSpec('planting_date', 'Planting date', date: true),
        const InputSpec('area', 'Planted area (ha)', number: true),
        const InputSpec('current_stage', 'Growth stage', choices: stages),
        const InputSpec(
          'status',
          'Season status',
          choices: {'active': 'Growing', 'completed': 'Completed'},
        ),
        const InputSpec(
          'end_date',
          'End date',
          date: true,
          required: false,
          help: 'Required only when the season is completed.',
        ),
      ],
      initial: {
        'variety': cycle?.variety ?? '',
        'planting_date':
            cycle?.plantingDate ??
            DateTime.now().toIso8601String().substring(0, 10),
        'area': cycle == null ? '' : '${cycle.area}',
        'current_stage': cycle?.stage ?? 'germination',
        'status': cycle?.status ?? 'active',
        'end_date': cycle?.endDate ?? '',
      },
      onSave: (data) async {
        await ref.read(cropRepositoryProvider).save({
          ...data,
          if (cycle == null) 'field': int.parse(data['field']!),
          if (cycle == null) 'crop_type': int.parse(data['crop_type']!),
          'end_date': data['end_date']!.isEmpty ? null : data['end_date'],
        }, cycle?.id);
        ref.invalidate(cyclesProvider);
        ref.invalidate(fieldsProvider);
      },
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }
}
