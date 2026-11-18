import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api.dart';
import '../../../core/theme.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final form = GlobalKey<FormState>();
  final username = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController(),
      email = TextEditingController();
  bool register = false, busy = false, obscure = true;
  String? error;
  @override
  void dispose() {
    for (final c in [username, password, name, email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final controller = ref.read(authProvider.notifier);
      if (register) {
        await controller.register(
          username.text.trim(),
          name.text.trim(),
          email.text.trim(),
          password.text,
        );
      } else {
        await controller.login(username.text.trim(), password.text);
      }
    } catch (e) {
      if (mounted) setState(() => error = apiError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= 900 && constraints.maxHeight >= 720;
        final panel = Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grass,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'FIELDBOOK / THE FARM JOURNAL',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(letterSpacing: 2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      register ? 'Plant your first page.' : 'Back to the land.',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      register
                          ? 'A place for your fields, seasons, and everyday work.'
                          : 'Your fields. Your seasons. Everything in its place.',
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      key: const Key('username'),
                      controller: username,
                      decoration: const InputDecoration(labelText: 'Username'),
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a username'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (register) ...[
                      TextFormField(
                        key: const Key('name'),
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Your name',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('email'),
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) =>
                            v == null ||
                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(v)
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      key: const Key('password'),
                      controller: password,
                      obscureText: obscure,
                      onFieldSubmitted: (_) {
                        if (!busy) submit();
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(
                            obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter your password'
                          : register && v.length < 8
                          ? 'Use at least 8 characters'
                          : null,
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('auth-submit'),
                        onPressed: busy ? null : submit,
                        child: Text(
                          busy
                              ? 'Opening your journal…'
                              : register
                              ? 'Create account'
                              : 'Open my journal',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              register = !register;
                              error = null;
                            }),
                      child: Text(
                        register
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        return Row(
          children: [
            if (wide)
              Expanded(
                child: Container(
                  color: FarmColors.olive,
                  padding: const EdgeInsets.all(64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wb_sunny_outlined,
                        color: FarmColors.wheat,
                        size: 64,
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'Good things\ntake tending.',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(color: FarmColors.paper, fontSize: 64),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'A quieter way to keep a growing farm in order.',
                        style: TextStyle(color: FarmColors.paper, fontSize: 18),
                      ),
                      const SizedBox(height: 64),
                      const Divider(color: Color(0xFF788262)),
                      const SizedBox(height: 12),
                      const Text(
                        'ROOTED IN THE EVERYDAY',
                        style: TextStyle(
                          color: FarmColors.wheat,
                          letterSpacing: 3,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: panel),
          ],
        );
      },
    ),
  );
}
