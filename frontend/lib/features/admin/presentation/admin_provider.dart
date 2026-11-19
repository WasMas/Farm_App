import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider(
  (ref) => AdminRepository(ref.watch(dioProvider)),
);

final adminDashboardProvider = FutureProvider(
  (ref) => ref.watch(adminRepositoryProvider).dashboard(),
);

final auditFiltersProvider =
    NotifierProvider<AuditFiltersNotifier, Map<String, String>>(
      AuditFiltersNotifier.new,
    );

class AuditFiltersNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => <String, String>{
    'action': '',
    'actor': '',
    'entity': '',
    'start': '',
    'end': '',
  };

  void setFilter(String key, String value) {
    state = {...state, key: value};
  }

  void clear() {
    state = <String, String>{
      'action': '',
      'actor': '',
      'entity': '',
      'start': '',
      'end': '',
    };
  }
}

final adminAuditProvider = FutureProvider((ref) {
  final filters = ref.watch(auditFiltersProvider);
  return ref
      .watch(adminRepositoryProvider)
      .audit(
        action: filters['action'],
        actor: filters['actor'],
        entity: filters['entity'],
        start: filters['start'],
        end: filters['end'],
      );
});
