import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../data/recommendation_repository.dart';

final recommendationRepositoryProvider = Provider(
  (ref) => RecommendationRepository(ref.watch(dioProvider)),
);

final recommendationsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(recommendationRepositoryProvider).list(),
);
