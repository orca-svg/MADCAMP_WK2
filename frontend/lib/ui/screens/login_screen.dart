import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Welcome Back', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Google 계정으로 로그인하세요.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : () => ref.read(authProvider.notifier).startGoogleLogin(),
              child: Text(auth.isLoading ? 'Starting...' : 'Google로 로그인'),
            ),
          ),
        ],
      ),
    );
  }
}
