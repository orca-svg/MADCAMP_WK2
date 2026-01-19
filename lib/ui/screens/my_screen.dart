import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/board_provider.dart';
import '../../providers/daily_message_provider.dart';

const _readableBodyFont = 'ChosunCentennial';

class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final myPosts = ref.watch(myPostsProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text('MY', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(
          '${authState.nickname ?? '리스너'} 님으로 로그인되어 있어요.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '아이디: ${authState.username ?? '-'}',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: '내 사연',
                value: myPosts.length.toString(),
              ),
            ),
            Expanded(
              child: _StatCard(
                label: '북마크',
                value: bookmarks.length.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('내가 쓴 사연', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: myPosts.length,
            itemBuilder: (context, index) {
              final post = myPosts[index];
              return Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: _readableBodyFont,
                      ),
                    ),
                    if (post.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _TagRow(tags: post.tags),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      post.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: _readableBodyFont,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            await ref.read(authProvider.notifier).signOut();
            ref.read(dailyMessageProvider.notifier).resetSession();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('로그아웃했어요.')),
            );
          },
          child: const Text('로그아웃'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleLarge),
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
