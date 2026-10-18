const stages = {
  'germination': 'Germination',
  'vegetative': 'Vegetative growth',
  'flowering': 'Flowering',
  'fruiting': 'Fruit development',
  'mature': 'Mature',
  'harvest': 'Harvest',
};

class CropType {
  CropType.fromJson(Map<String, dynamic> j)
    : id = j['id'] as int,
      name = j['name'] as String,
      description = j['description'] as String;
  final int id;
  final String name, description;
}

class CropCycle {
  CropCycle.fromJson(Map<String, dynamic> j)
    : id = j['id'] as int,
      field = j['field'] as int,
      type = j['crop_type'] as int,
      name = j['crop_name'] as String,
      fieldName = j['field_name'] as String,
      farmName = j['farm_name'] as String,
      variety = j['variety'] as String,
      plantingDate = j['planting_date'] as String,
      endDate = j['end_date'] as String?,
      stage = j['current_stage'] as String,
      status = j['status'] as String,
      area = double.parse('${j['area']}'),
      canEdit = j['can_edit'] == true;
  final int id, field, type;
  final String name, fieldName, farmName, variety, plantingDate, stage, status;
  final String? endDate;
  final double area;
  final bool canEdit;
}
