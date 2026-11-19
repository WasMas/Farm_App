import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api.dart';
import '../../../core/widgets/page_parts.dart';
import '../../../core/widgets/record_form.dart';
import '../../crops/presentation/crop_providers.dart';
import 'prediction_provider.dart';

class PredictionsScreen extends ConsumerWidget {
  const PredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      const PageHeading(
        'Predictions.',
        'Disease checks and yield estimates, saved for later review.',
      ),
      const SizedBox(height: 24),
      Card(
        child: ListTile(
          leading: const Icon(Icons.health_and_safety_outlined),
          title: const Text('Disease risk'),
          subtitle: const Text('Upload a clear leaf photo'),
          trailing: FilledButton.icon(
            onPressed: () => _disease(context, ref),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Check photo'),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.analytics_outlined),
          title: const Text('Expected yield'),
          subtitle: const Text('Estimate production for a planting'),
          trailing: FilledButton.icon(
            onPressed: () => _yield(context, ref),
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Estimate'),
          ),
        ),
      ),
      const SizedBox(height: 32),
      Text(
        'Prediction history',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      ref.watch(predictionHistoryProvider).when(
        loading: () => const LinearProgressIndicator(),
        error: (error, _) => ErrorState(
          error,
          () => ref.invalidate(predictionHistoryProvider),
        ),
        data: (records) => records.isEmpty
            ? const EmptyState(
                'No saved predictions',
                'Your disease checks and yield estimates will appear here.',
              )
            : Column(
                children: [
                  for (final record in records)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          record['kind'] == 'disease'
                              ? Icons.health_and_safety_outlined
                              : Icons.analytics_outlined,
                        ),
                        title: Text(_historyTitle(record)),
                        subtitle: Text(
                          '${record['kind'] == 'disease' ? 'Disease' : 'Yield'}  ·  ${record['created_at']}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showResult(
                          context,
                          record['kind'] == 'disease'
                              ? 'Saved disease prediction'
                              : 'Saved yield estimate',
                          Map<String, dynamic>.from(record['result'] as Map),
                          imageUrl: record['image'] as String?,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    ],
  );

  Future<void> _disease(BuildContext context, WidgetRef ref) async {
    BuildContext? loadingContext;
    final loadingShown = Completer<void>();
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null || !context.mounted) return;

      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogContext) {
          loadingContext = dialogContext;
          if (!loadingShown.isCompleted) loadingShown.complete();
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(child: Text('Analyzing the leaf photo…')),
              ],
            ),
          );
        },
      );
      await loadingShown.future;

      final result =
          await ref.read(predictionRepositoryProvider).disease(image);
      ref.invalidate(predictionHistoryProvider);
      if (loadingContext != null && loadingContext!.mounted) {
        Navigator.of(loadingContext!, rootNavigator: true).pop();
      }
      if (context.mounted) {
        await _showResult(
          context,
          'Disease prediction',
          result,
          image: image,
        );
      }
    } catch (error) {
      if (loadingContext != null && loadingContext!.mounted) {
        Navigator.of(loadingContext!, rootNavigator: true).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(error))));
      }
    }
  }

  Future<void> _yield(BuildContext context, WidgetRef ref) async {
    final cycles = await ref.read(cyclesProvider.future);
    if (!context.mounted) return;
    if (cycles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Begin a planting before estimating yield.')),
      );
      return;
    }
    try {
      Map<String, dynamic>? result;
      await showRecordForm(
        context,
        title: 'Expected yield',
        fields: [
          InputSpec(
            'cycle',
            'Planting',
            choices: {
              for (final cycle in cycles)
                '${cycle.id}': '${cycle.name} / ${cycle.fieldName}',
            },
          ),
        ],
        onSave: (data) async {
          result = await ref
              .read(predictionRepositoryProvider)
              .yieldEstimate(int.parse(data['cycle']!));
          ref.invalidate(predictionHistoryProvider);
        },
      );
      if (context.mounted && result != null) {
        await _showResult(context, 'Yield estimate', result!);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(error))));
      }
    }
  }

  Future<void> _showResult(
    BuildContext context,
    String title,
    Map<String, dynamic> result, {
    XFile? image,
    String? imageUrl,
  }
  ) async {
    final probability = result['probability'];
    final confidence = probability is num
        ? '${(probability * 100).round()}%'
        : null;
    final imageBytes = image == null ? null : await image.readAsBytes();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 260,
                        maxWidth: 520,
                      ),
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  )
                else if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 260,
                        maxWidth: 520,
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),
                if (imageBytes != null || imageUrl != null)
                  const SizedBox(height: 16),
                Text(
                  result['prediction']?.toString() ??
                      result['crop']?.toString() ??
                      'Prediction',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (confidence != null) ...[
                  const SizedBox(height: 12),
                  Text('Confidence: $confidence'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (probability as num).toDouble().clamp(0.0, 1.0),
                  ),
                ],
                if ((result['disclaimer']?.toString() ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(result['disclaimer'].toString()),
                ],
                if (result['actions'] is List) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Recommended next steps',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final action in result['actions'] as List)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $action'),
                    ),
                ],
                if (result['estimated_production_kg'] is Map) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Estimated production: '
                    '${result['estimated_production_kg']['low']}–'
                    '${result['estimated_production_kg']['high']} kg',
                  ),
                  Text(
                    'Expected harvest date: ${result['expected_harvest_date']}',
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              final navigator = Navigator.of(dialogContext, rootNavigator: true);
              if (navigator.canPop()) navigator.pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _historyTitle(Map<String, dynamic> record) {
    final result = Map<String, dynamic>.from(record['result'] as Map);
    return result['prediction']?.toString() ??
        result['crop']?.toString() ??
        'Prediction';
  }
}
