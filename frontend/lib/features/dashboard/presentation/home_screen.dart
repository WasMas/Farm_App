import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fieldbook'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ref.read(authProvider.notifier).logout();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Signed out on this device. The server could not be reached.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.name.isNotEmpty == true ? user!.name : user?.username ?? ''}.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Your farm journal is ready. Account role: ${user?.role ?? ''}.',
            ),
          ],
        ),
      ),
    );
  }
}
