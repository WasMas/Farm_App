import 'package:fieldbook/features/activities/domain/activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Activity quantity keeps its precision and uses the display unit', () {
    final record = {
      'id': 1,
      'cycle': 1,
      'kind': 'irrigation',
      'date': '2026-11-22',
      'quantity': '12.500',
      'unit': 'm3',
      'product': '',
      'notes': '',
      'crop_name': 'Olive',
      'field_name': 'North',
      'farm_name': 'Grove',
      'author_name': 'Owner',
    };
    expect(ActivityRecord.fromJson(record).amount, '12.5 m³');
    expect(ActivityRecord.fromJson({...record, 'quantity': null}).amount, '');
  });
}
