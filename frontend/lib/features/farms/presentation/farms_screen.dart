import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/page_parts.dart';
import '../../auth/presentation/auth_provider.dart';
import 'farm_forms.dart';
import 'farm_providers.dart';

class FarmsScreen extends ConsumerWidget {
  const FarmsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      PageHeading(
        'Your land.',
        'Every farm has a story. Keep yours here.',
        action: ref.watch(authProvider).asData?.value?.role == 'expert'
            ? null
            : FilledButton.icon(
                onPressed: () => editFarm(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add farm'),
              ),
      ),
      ref
          .watch(farmsProvider)
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorState(e, () => ref.invalidate(farmsProvider)),
            data: (farms) => farms.isEmpty
                ? const EmptyState(
                    'Room to grow',
                    'Add your first farm, then mark out its fields.',
                  )
                : LayoutBuilder(
                    builder: (context, size) => Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        for (final farm in farms)
                          SizedBox(
                            width: size.maxWidth < 650
                                ? size.maxWidth
                                : (size.maxWidth - 20) / 2,
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => context.go('/farms/${farm.id}'),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.landscape_outlined,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            size: 32,
                                          ),
                                          const Spacer(),
                                          const Icon(
                                            Icons.arrow_outward,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 28),
                                      Text(
                                        farm.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(farm.location),
                                      const SizedBox(height: 24),
                                      const Divider(),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${farm.area.toStringAsFixed(2)} ha   /   ${farm.fieldCount} fields',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
    ],
  );
}
