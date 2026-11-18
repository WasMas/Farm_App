import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../data/prediction_repository.dart';

final predictionRepositoryProvider = Provider(
  (ref) => PredictionRepository(ref.watch(dioProvider)),
);

final predictionHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>(
      (ref) => ref.watch(predictionRepositoryProvider).history(),
    );
