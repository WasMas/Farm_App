import 'package:fieldbook/features/auth/domain/app_user.dart';
import 'package:fieldbook/features/auth/presentation/auth_provider.dart';

class SignedInController extends AuthController {
  @override
  Future<AppUser?> build() async => const AppUser(
    id: 1,
    username: 'amina',
    name: 'Amina',
    email: 'amina@example.test',
    role: 'farmer',
    isAdmin: false,
  );
}
