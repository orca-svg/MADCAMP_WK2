import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/board_repository.dart';
import '../../providers/board_provider.dart';

// Speaker texture (consistent with my_screen)
const String _speakerTexturePath = 'assets/textures/fabric_grille.png';
const Color _speakerBase = Color(0xFF171411);

BoxDecoration _speakerTextureDecoration() {
  return BoxDecoration(
    color: _speakerBase,
    image: DecorationImage(
      image: const AssetImage(_speakerTexturePath),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(
        const Color(0xFF0B0908).withValues(alpha: 0.35),
        BlendMode.darken,
      ),
    ),
  );
}

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPosts = ref.watch(myPostsProvider);
    final theme = Theme.of(context);

    return Container(
      decoration: _speakerTextureDecoration(),
      child: Column(
        children: [
          // Header - matches bookmarks screen style
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: _HeaderCard(
              title: '내가 공유한 글',
              subtitle: '공유한 글 ${myPosts.length}개',
              onBack: () => context.pop(),
            ),
          ),
          // List
          Expanded(
            child: myPosts.isEmpty
                ? Center(
                    child: Text(
                      '아직 공유한 글이 없어요.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xAAD7CCB9),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: myPosts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final post = myPosts[index];
                      return _PostRow(
                        post: post,
                        onTap: () => context.push('/my/detail/${post.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PostRow extends StatelessWidget {
  const _PostRow({required this.post, required this.onTap});

  final BoardPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tagDisplay = post.tags.isNotEmpty
        ? post.tags.first + (post.tags.length > 1 ? ' +${post.tags.length - 1}' : '')
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x1A171411),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x1FD7CCB9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                post.title.isNotEmpty ? post.title : '(제목 없음)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF2EBDD),
                ),
              ),
              const SizedBox(height: 6),
              // Tag + Stats row
              Row(
                children: [
                  if (tagDisplay.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x24171411),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x2ED7CCB9)),
                      ),
                      child: Text(
                        tagDisplay,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xAAD7CCB9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  // Comment count
                  const Icon(Icons.chat_bubble_outline, size: 12, color: Color(0x99D7CCB9)),
                  const SizedBox(width: 3),
                  Text(
                    '${post.commentCount}',
                    style: const TextStyle(fontSize: 10, color: Color(0x99D7CCB9)),
                  ),
                  const SizedBox(width: 10),
                  // Like count
                  const Icon(Icons.favorite_border, size: 12, color: Color(0x99D7CCB9)),
                  const SizedBox(width: 3),
                  Text(
                    '${post.likeCount}',
                    style: const TextStyle(fontSize: 10, color: Color(0x99D7CCB9)),
                  ),
                  const SizedBox(width: 10),
                  // Date
                  Text(
                    _formatDate(post.createdAt),
                    style: const TextStyle(fontSize: 10, color: Color(0x88D7CCB9)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xE61F1A17),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22D7CCB9), width: 1),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x14171411),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFFD7CCB9),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (theme.textTheme.headlineSmall ?? theme.textTheme.titleLarge)?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFF2EBDD),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD7CCB9).withValues(alpha: 0.80),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
