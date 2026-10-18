import '../../activities/domain/activity.dart';
import '../../crops/domain/crop_cycle.dart';

class FarmSummary {
  FarmSummary.fromJson(Map<String, dynamic> j)
    : farms = j['farms'] as int,
      fields = j['fields'] as int,
      activeCycles = j['active_cycles'] as int,
      activitiesWeek = j['activities_week'] as int,
      area = double.parse('${j['total_area']}'),
      irrigation = double.parse('${j['irrigation_m3_week']}'),
      harvest = double.parse('${j['harvest_kg']}'),
      harvestItems = double.parse('${j['harvest_items']}'),
      plantings = (j['plantings'] as List)
          .map((v) => CropCycle.fromJson(v))
          .toList(),
      recent = (j['recent_activities'] as List)
          .map((v) => ActivityRecord.fromJson(v))
          .toList();
  final int farms, fields, activeCycles, activitiesWeek;
  final double area, irrigation, harvest, harvestItems;
  final List<CropCycle> plantings;
  final List<ActivityRecord> recent;
}
