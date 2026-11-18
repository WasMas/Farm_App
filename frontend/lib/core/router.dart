import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/home_screen.dart';
import '../features/farms/presentation/farms_screen.dart';
import '../features/farms/presentation/farm_detail_screen.dart';
import 'widgets/farm_shell.dart';
import '../features/crops/presentation/crops_screen.dart';
import '../features/crops/presentation/crop_types_screen.dart';
import '../features/activities/presentation/activities_screen.dart';
import '../features/weather/presentation/weather_screen.dart';
import '../features/auth/presentation/profile_screen.dart';

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
      ShellRoute(
        builder: (_, _, child) => FarmShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/crops', builder: (_, _) => const CropsScreen()),
          GoRoute(path: '/weather', builder: (_, _) => const WeatherScreen()),
          GoRoute(
            path: '/activities',
            builder: (_, _) => const ActivitiesScreen(),
          ),
          GoRoute(
            path: '/crops/types',
            builder: (_, _) => const CropTypesScreen(),
          ),
          GoRoute(path: '/farms', builder: (_, _) => const FarmsScreen()),
          GoRoute(
            path: '/farms/:id',
            builder: (_, state) => FarmDetailScreen(
              int.tryParse(state.pathParameters['id']!) ?? -1,
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
  ref.listen(authProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
