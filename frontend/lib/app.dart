import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api.dart';
import 'core/theme.dart';

final healthProvider = FutureProvider(
  (ref) async =>
      (await ref.watch(dioProvider).get('health/')).data
          as Map<String, dynamic>,
);

class FieldbookApp extends ConsumerWidget {
  const FieldbookApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'Fieldbook',
    debugShowCheckedModeBanner: false,
    theme: farmTheme(),
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.grass, size: 48),
                const SizedBox(height: 24),
                Text(
                  'Fieldbook',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                const Text('A little order. A better growing day.'),
                const SizedBox(height: 32),
                ref
                    .watch(healthProvider)
                    .when(
                      data: (data) => Text(
                        'Django + ${data['database']} · ${data['status']}',
                      ),
                      error: (e, _) => Text(apiError(e)),
                      loading: () => const LinearProgressIndicator(),
                    ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
