import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/record_form.dart';
import '../domain/farm.dart';
import 'farm_location_picker_screen.dart';
import 'farm_providers.dart';

Future<void> editFarm(BuildContext context, WidgetRef ref, [Farm? farm]) async {
  await showRecordForm(
    context,
    title: farm == null ? 'A new piece of land' : 'Edit farm',
    fields: const [
      InputSpec('name', 'Farm name'),
      InputSpec('location', 'Location'),
      InputSpec('total_area', 'Total area (ha)', number: true),
      InputSpec(
        'latitude',
        'Latitude',
        required: false,
        number: true,
        help: 'Optional coordinates enable local weather.',
      ),
      InputSpec('longitude', 'Longitude', required: false, number: true),
    ],
    initial: farm == null
        ? {}
        : {
            'name': farm.name,
            'location': farm.location,
            'total_area': '${farm.area}',
            'latitude': farm.latitude ?? '',
            'longitude': farm.longitude ?? '',
          },
    locationPickerBuilder: (onSelected) => FarmLocationPickerPanel(
      onSelected: (location, displayName) => onSelected({
        'location': displayName,
        'latitude': location.latitude.toStringAsFixed(6),
        'longitude': location.longitude.toStringAsFixed(6),
      }),
    ),
    onSave: (data) async {
      await ref.read(farmRepositoryProvider).saveFarm({
        ...data,
        'latitude': data['latitude']!.isEmpty ? null : data['latitude'],
        'longitude': data['longitude']!.isEmpty ? null : data['longitude'],
      }, farm?.id);

      ref.invalidate(farmsProvider);
      if (farm != null) ref.invalidate(farmProvider(farm.id));
    },
  );
}

Future<void> editField(
  BuildContext context,
  WidgetRef ref,
  int farmId, [
  FarmField? field,
]) async {
  await showRecordForm(
    context,
    title: field == null ? 'Mark out a field' : 'Edit field',
    fields: const [
      InputSpec('name', 'Field name'),
      InputSpec('area', 'Area (ha)', number: true),
      InputSpec(
        'soil_type',
        'Soil type',
        choices: {
          'sandy': 'Sandy',
          'clay': 'Clay',
          'loam': 'Loam',
          'silt': 'Silt',
          'other': 'Other',
        },
      ),
    ],
    initial: field == null
        ? {}
        : {
            'name': field.name,
            'area': '${field.area}',
            'soil_type': field.soil,
          },
    onSave: (data) async {
      await ref.read(farmRepositoryProvider).saveField({
        ...data,
        'farm': farmId,
      }, field?.id);

      ref.invalidate(fieldsProvider);
      ref.invalidate(farmsProvider);
      ref.invalidate(farmProvider(farmId));
    },
  );
}
