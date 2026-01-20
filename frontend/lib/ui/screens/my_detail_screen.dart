import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/board_repository.dart';
import '../../providers/board_provider.dart';

class MyDetailScreen extends ConsumerWidget {
  const MyDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final board = ref.watch(boardControllerProvider);
    BoardPost? post;
    for (final item in board.myPosts) {
      if (item.id == postId) {
        post = item;
        break;
      }
    }

    if (post == null) {
      return Center(
        child: Text(
          '게시글을 찾을 수 없어요.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            post.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFF2EBDD).withOpacity(0.92),
            ),
          ),
          const SizedBox(height: 10),
          if (post.tags.isNotEmpty) ...[
            _TagRow(tags: post.tags),
            const SizedBox(height: 10),
          ],
          Text(
            post.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 14,
              height: 1.4,
              color: const Color(0xFFF2EBDD).withOpacity(0.90),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < tags.length; i++) ...[
            _TagChip(text: tags[i]),
            if (i != tags.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0x24171411),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xEBD7CCB9),
          ),
        ),
      ),
    );
  }
}
