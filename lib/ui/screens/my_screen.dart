import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/daily_message_provider.dart';

class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('My Dial', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(
          'Signed in as ${authState.nickname ?? 'Listener'}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Username: ${authState.username ?? '-'}',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            await ref.read(authProvider.notifier).signOut();
            ref.read(dailyMessageProvider.notifier).resetSession();
            if (context.mounted) {
              context.go('/login');
            }
          },
          child: const Text('Sign Out'),
        ),
      ],
    );
  }
}
