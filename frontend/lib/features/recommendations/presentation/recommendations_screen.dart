import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../../../core/widgets/page_parts.dart';
import '../../auth/presentation/auth_provider.dart';
import 'recommendation_provider.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends ConsumerState<RecommendationsScreen> {
  DateTime? simulatedDate;

  @override
  Widget build(BuildContext context) {
    final recommendations = ref.watch(recommendationsProvider);
    final user = ref.watch(authProvider).asData?.value;
    final canDecide =
        user?.isAdmin == true || user?.role == 'owner' || user?.role == 'farmer';
    return RefreshIndicator(
      onRefresh: () => ref.refresh(recommendationsProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          PageHeading(
            'Recommendations.',
            'Review calendar, soil, activity, and weather suggestions before they change your farm data.',
            action: FilledButton.icon(
              onPressed: _checkCalendar,
              icon: const Icon(Icons.refresh),
              label: Text(
                simulatedDate == null
                    ? 'Check calendar'
                    : 'Check ${_date(simulatedDate!)}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Use the date picker to demonstrate future recommendations without changing the server clock.',
          ),
          const SizedBox(height: 24),
          recommendations.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) =>
                ErrorState(error, () => ref.invalidate(recommendationsProvider)),
            data: (items) {
              final pending = items.where((item) => item['status'] == 'pending');
              if (pending.isEmpty) {
                return const EmptyState(
                  'No pending recommendations',
                  'Check the calendar after planting or activity dates become due.',
                );
              }
              return Column(
                children: [
                  for (final item in pending)
                    _RecommendationCard(item, canDecide: canDecide),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _checkCalendar() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: simulatedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Check recommendations as of',
    );
    if (!mounted || chosen == null) return;
    setState(() => simulatedDate = chosen);
    try {
      await ref.read(recommendationRepositoryProvider).check(asOf: chosen);
      ref.invalidate(recommendationsProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(error))));
      }
    }
  }

  String _date(DateTime value) => value.toIso8601String().substring(0, 10);
}

class _RecommendationCard extends ConsumerWidget {
  const _RecommendationCard(this.item, {required this.canDecide});
  final Map<String, dynamic> item;
  final bool canDecide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['title'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('${item['farm_name']} · ${item['field_name']}'),
            const SizedBox(height: 12),
            Text(item['message'] as String),
            const SizedBox(height: 8),
            Text('Due: ${item['due_date']}'),
            Text(
              'Source: ${item['source']}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (canDecide) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => _decide(context, ref, true),
                    child: const Text('Accept'),
                  ),
                  OutlinedButton(
                    onPressed: () => _decide(context, ref, false),
                    child: const Text('Refuse'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    bool accept,
  ) async {
    try {
      await ref
          .read(recommendationRepositoryProvider)
          .decide(item['id'] as int, accept);
      ref.invalidate(recommendationsProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(error))));
      }
    }
  }
}
