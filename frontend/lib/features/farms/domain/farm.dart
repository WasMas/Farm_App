class Farm {
  Farm.fromJson(Map<String, dynamic> j)
    : id = j['id'] as int,
      name = j['name'] as String,
      location = j['location'] as String,
      area = double.parse('${j['total_area']}'),
      fieldCount = j['field_count'] as int,
      latitude = j['latitude']?.toString(),
      longitude = j['longitude']?.toString(),
      canEdit = j['can_edit'] == true,
      canShare = j['can_share'] == true,
      canWork = j['can_work'] == true;
  final int id, fieldCount;
  final String name, location;
  final double area;
  final String? latitude, longitude;
  final bool canEdit, canShare, canWork;
}

class FarmField {
  FarmField.fromJson(Map<String, dynamic> j)
    : id = j['id'] as int,
      farmId = j['farm'] as int,
      name = j['name'] as String,
      farmName = j['farm_name'] as String,
      area = double.parse('${j['area']}'),
      soil = j['soil_type'] as String,
      canEdit = j['can_edit'] == true,
      assignedWorkers = (j['assigned_workers'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
  final int id, farmId;
  final String name, farmName, soil;
  final double area;
  final bool canEdit;
  final List<Map<String, dynamic>> assignedWorkers;
}
