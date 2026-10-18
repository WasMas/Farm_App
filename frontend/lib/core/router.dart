import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isLoading) {
        return state.uri.path == '/loading' ? null : '/loading';
      }
      final loggedIn = auth.asData?.value != null;
      if (!loggedIn) return state.uri.path == '/login' ? null : '/login';
      if (state.uri.path == '/login' || state.uri.path == '/loading') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    ],
  );
  ref.listen(authProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
