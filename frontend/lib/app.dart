import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api.dart';
import 'core/theme.dart';
import 'core/router.dart';

final healthProvider = FutureProvider(
  (ref) async =>
      (await ref.watch(dioProvider).get('health/')).data
          as Map<String, dynamic>,
);

class FieldbookApp extends ConsumerWidget {
  const FieldbookApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Fieldbook',
    debugShowCheckedModeBanner: false,
    theme: farmTheme(),
    routerConfig: ref.watch(routerProvider),
  );
}
