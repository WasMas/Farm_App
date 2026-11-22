import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/page_parts.dart';
import '../../activities/presentation/activity_form.dart';
import '../../activities/presentation/activity_tile.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../crops/domain/crop_cycle.dart';
import '../domain/farm_summary.dart';
import '../../farms/presentation/farm_providers.dart';
import 'dashboard_provider.dart';
import 'field_sketch.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).asData?.value;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          PageHeading(
            'A good day to grow.',
            DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
            action: MediaQuery.sizeOf(context).width < 900
                ? null
                : IconButton(
                    tooltip: 'Refresh journal',
                    onPressed: () => ref.invalidate(dashboardProvider),
                    icon: const Icon(Icons.refresh),
                  ),
          ),
          if (ref.watch(farmsProvider).asData?.value case final farms?
              when farms.isNotEmpty)
            DropdownButton<int>(
              hint: const Text('All farms'),
              value:
                  farms.any(
                    (farm) => farm.id == ref.watch(dashboardFarmProvider),
                  )
                  ? ref.watch(dashboardFarmProvider)
                  : null,
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('All farms'),
                ),
                for (final farm in farms)
                  DropdownMenuItem(value: farm.id, child: Text(farm.name)),
              ],
              onChanged: ref.read(dashboardFarmProvider.notifier).select,
            ),
          ref
              .watch(dashboardProvider)
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) =>
                    ErrorState(e, () => ref.invalidate(dashboardProvider)),
                data: (summary) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _JournalHero(
                      summary: summary,
                      onAction: () {
                        if (summary.farms == 0 || summary.fields == 0) {
                          context.go('/farms');
                        } else if (summary.activeCycles == 0) {
                          context.go('/crops');
                        } else {
                          recordWork(context, ref);
                        }
                      },
                      canRecord: user?.role != 'worker',
                    ),
                    const SizedBox(height: 24),
                    _SummaryFigures(summary),
                    const SizedBox(height: 36),
                    LayoutBuilder(
                      builder: (context, size) {
                        final journal = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 16,
                              children: [
                                Text(
                                  'Latest from the journal',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                TextButton(
                                  onPressed: () => context.go('/activities'),
                                  child: const Text('All records →'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (summary.recent.isEmpty)
                              const EmptyState(
                                'The first page is yours',
                                'Your fieldwork and observations will appear here.',
                              )
                            else
                              for (final activity in summary.recent) ...[
                                ActivityTile(activity),
                                const Divider(height: 1),
                              ],
                          ],
                        );
                        final plantings = Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'In the ground',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${summary.activeCycles} active planting cycles',
                                ),
                                const SizedBox(height: 24),
                                if (summary.plantings.isEmpty)
                                  const Text(
                                    'Begin a planting to follow its growth here.',
                                  ),
                                for (final planting in summary.plantings)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          planting.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        Text(
                                          '${planting.fieldName} · ${stages[planting.stage]}',
                                        ),
                                        const SizedBox(height: 12),
                                        LinearProgressIndicator(
                                          value:
                                              (stages.keys.toList().indexOf(
                                                    planting.stage,
                                                  ) +
                                                  1) /
                                              stages.length,
                                          minHeight: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                const Divider(),
                                const SizedBox(height: 12),
                                Text(
                                  'Water recorded this week',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${summary.irrigation.toStringAsFixed(1)} m³',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                TextButton(
                                  onPressed: () => context.go('/crops'),
                                  child: const Text('Visit your plantings →'),
                                ),
                              ],
                            ),
                          ),
                        );
                        return size.maxWidth >= 850
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 2, child: journal),
                                  const SizedBox(width: 32),
                                  Expanded(child: plantings),
                                ],
                              )
                            : Column(
                                children: [
                                  journal,
                                  const SizedBox(height: 32),
                                  plantings,
                                ],
                              );
                      },
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _JournalHero extends StatelessWidget {
  const _JournalHero({
    required this.summary,
    required this.onAction,
    required this.canRecord,
  });
  final FarmSummary summary;
  final VoidCallback onAction;
  final bool canRecord;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: FarmColors.olive,
      borderRadius: BorderRadius.circular(10),
    ),
    child: LayoutBuilder(
      builder: (context, size) {
        final words = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ROOTED IN THE EVERYDAY',
              style: TextStyle(
                color: FarmColors.wheat,
                letterSpacing: 2,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Keep close to\nwhat’s growing.',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: FarmColors.paper, fontSize: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              'A little attention today. A story to learn from tomorrow.',
              style: TextStyle(color: Color(0xFFDFE4D2)),
            ),
            const SizedBox(height: 24),
            if (canRecord)
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: FarmColors.wheat,
                  foregroundColor: FarmColors.olive,
                ),
                child: Text(
                  summary.farms == 0
                      ? 'Add your first farm'
                      : summary.fields == 0
                      ? 'Mark out your fields'
                      : summary.activeCycles == 0
                      ? 'Begin a planting'
                      : 'Record today’s work',
                ),
              ),
          ],
        );
        return size.maxWidth >= 650
            ? Row(
                children: [
                  Expanded(child: words),
                  const SizedBox(width: 24),
                  const SizedBox(
                    width: 280,
                    height: 180,
                    child: CustomPaint(painter: FieldSketch()),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  words,
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: double.infinity,
                    height: 140,
                    child: CustomPaint(painter: FieldSketch()),
                  ),
                ],
              );
      },
    ),
  );
}

class _SummaryFigures extends StatelessWidget {
  const _SummaryFigures(this.summary);
  final FarmSummary summary;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final columns = size.maxWidth >= 1000 ? 4 : 2;
      final width = (size.maxWidth - (columns - 1) * 14) / columns;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final figure in [
            (
              label: 'Land in care',
              value: summary.area.toStringAsFixed(2),
              detail:
                  'ha · ${summary.farms} ${summary.farms == 1 ? 'farm' : 'farms'}',
            ),
            (
              label: 'Growing now',
              value: '${summary.activeCycles}',
              detail: 'plantings · ${summary.fields} fields',
            ),
            (
              label: 'This week’s work',
              value: '${summary.activitiesWeek}',
              detail: 'recorded activities',
            ),
            (
              label: 'Harvest to date',
              value: summary.harvest.toStringAsFixed(1),
              detail: summary.harvestItems > 0
                  ? 'kg + ${summary.harvestItems.toStringAsFixed(0)} items'
                  : 'kg recorded',
            ),
          ])
            SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        figure.label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 20),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          figure.value,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        figure.detail,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
