const activityKinds = {
  'irrigation': 'Irrigation',
  'fertilization': 'Fertilization',
  'treatment': 'Treatment',
  'observation': 'Observation',
  'harvest': 'Harvest',
};
const unitLabels = {
  'm3': 'm³',
  'l': 'litres',
  'ml': 'ml',
  'kg': 'kg',
  'g': 'g',
  't': 'tonnes',
  'items': 'items',
};
const activityUnits = {
  'irrigation': ['m3', 'l'],
  'fertilization': ['kg', 'g', 'l'],
  'treatment': ['kg', 'g', 'l', 'ml'],
  'harvest': ['kg', 't', 'items'],
};

class ActivityRecord {
  ActivityRecord.fromJson(Map<String, dynamic> j)
    : id = j['id'] as int,
      cycle = j['cycle'] as int,
      kind = j['kind'] as String,
      date = j['date'] as String,
      quantity = j['quantity'] == null
          ? null
          : double.parse('${j['quantity']}'),
      unit = j['unit'] as String,
      product = j['product'] as String,
      notes = j['notes'] as String,
      cropName = j['crop_name'] as String,
      fieldName = j['field_name'] as String,
      farmName = j['farm_name'] as String,
      author = j['author_name'] as String,
      canEdit = j['can_edit'] == true;
  final int id, cycle;
  final String kind,
      date,
      unit,
      product,
      notes,
      cropName,
      fieldName,
      farmName,
      author;
  final double? quantity;
  final bool canEdit;
  String get amount => quantity == null
      ? ''
      : '${quantity!.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '')} ${unitLabels[unit] ?? unit}';
}
