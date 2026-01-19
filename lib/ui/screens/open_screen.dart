import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/board_provider.dart';

const _readableBodyFont = 'ChosunCentennial';

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
              return Container(
                margin: const EdgeInsets.all(10),
                child: Material(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => context.go('/open/${post.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                fit: FlexFit.loose,
                                child: _TagRow(tags: post.tags),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(post.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: _readableBodyFont,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: _readableBodyFont,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            post.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: _readableBodyFont,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
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
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
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
