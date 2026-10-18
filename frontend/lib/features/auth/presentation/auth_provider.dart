import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../../../core/session_store.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider(
  (ref) =>
      AuthRepository(ref.watch(dioProvider), ref.watch(tokenStoreProvider)),
);
final authProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);
final signedInUserProvider = Provider<AppUser>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) {
    throw StateError('Sign in to open your farm journal.');
  }
  return user;
});

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final subscription = ref
        .watch(sessionExpiredProvider)
        .stream
        .listen((_) => state = const AsyncData(null));
    ref.onDispose(subscription.cancel);
    return ref.watch(authRepositoryProvider).restore();
  }

  Future<void> login(String username, String password) async {
    state = AsyncData(
      await ref.read(authRepositoryProvider).login(username, password),
    );
  }

  Future<void> register(
    String username,
    String name,
    String email,
    String password,
  ) async {
    state = AsyncData(
      await ref
          .read(authRepositoryProvider)
          .register(username, name, email, password),
    );
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } finally {
      state = const AsyncData(null);
    }
  }
}
