import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/board_provider.dart';
import '../widgets/post_preview_card.dart';

class OpenScreen extends ConsumerWidget {
  const OpenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(boardControllerProvider).openPosts;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text('열린 주파수', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(
          '다른 사람들의 주파수를 둘러보세요.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostPreviewCard(
                title: post.title,
                body: post.body,
                createdAt: post.createdAt,
                tags: post.tags,
                onTap: () => context.go('/open/${post.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
