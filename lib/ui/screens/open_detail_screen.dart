import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/board_provider.dart';

const _readableBodyFont = 'ChosunCentennial';

class OpenDetailScreen extends ConsumerWidget {
  const OpenDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(boardPostProvider(postId));
    final theme = Theme.of(context);

    if (post == null) {
      return Center(
        child: Text(
          '주파수를 찾을 수 없어요.',
          style: theme.textTheme.titleMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text('열린 주파수', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(
          post.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: _readableBodyFont,
          ),
        ),
        const SizedBox(height: 10),
        if (post.tags.isNotEmpty) ...[
          _TagRow(tags: post.tags),
          const SizedBox(height: 8),
        ],
        Text(
          _formatTime(post.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: _readableBodyFont,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Text(
                post.body,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: _readableBodyFont,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => context.go('/open'),
          icon: const Icon(Icons.chevron_left),
          label: const Text('목록으로'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('공감이 전송됐어요.')),
                  );
                },
                icon: const Icon(Icons.favorite_border),
                label: const Text('공감'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('채택 요청을 보냈어요.')),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('채택'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final visibleTags = tags.take(3).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in visibleTags) _TagChip(text: tag),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0x33171411),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xE6F2EBDD),
                fontFamily: _readableBodyFont,
              ),
        ),
      ),
    );
  }
}
