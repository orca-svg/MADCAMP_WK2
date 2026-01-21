import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/comments_repository.dart';
import '../../providers/comments_provider.dart';

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

class AdoptedComfortsScreen extends ConsumerWidget {
  const AdoptedComfortsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adoptedAsync = ref.watch(myAdoptedCommentsProvider);
    final theme = Theme.of(context);

    return Container(
      decoration: _speakerTextureDecoration(),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                    color: Color(0xFFD7CCB9),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '채택된 위로',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF2EBDD),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x22D7CCB9)),
          // Content
          Expanded(
            child: adoptedAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xAAD7CCB9)),
              ),
              error: (_, _) => Center(
                child: Text(
                  '불러오는 중 오류가 발생했어요.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xAAD7CCB9),
                  ),
                ),
              ),
              data: (comments) => comments.isEmpty
                  ? _EmptyState(theme: theme)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: comments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return _AdoptedCommentRow(
                          comment: comment,
                          onTap: () => context.push('/open/${comment.storyId}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 48,
            color: Color(0x66D7CCB9),
          ),
          const SizedBox(height: 16),
          Text(
            '아직 채택된 위로가 없어요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xAAD7CCB9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 사람의 사연에 위로를 남겨보세요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0x77D7CCB9),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdoptedCommentRow extends StatelessWidget {
  const _AdoptedCommentRow({required this.comment, required this.onTap});

  final AdoptedComment comment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              // Story title
              Row(
                children: [
                  const Icon(
                    Icons.verified,
                    size: 14,
                    color: Color(0xAAD7CCB9),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      comment.storyTitle.isNotEmpty
                          ? comment.storyTitle
                          : '(제목 없음)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xAAD7CCB9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Comment content
              Text(
                comment.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF2EBDD),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              // Stats row
              Row(
                children: [
                  const Spacer(),
                  const Icon(Icons.favorite_border, size: 12, color: Color(0x99D7CCB9)),
                  const SizedBox(width: 3),
                  Text(
                    '${comment.likeCount}',
                    style: const TextStyle(fontSize: 10, color: Color(0x99D7CCB9)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDate(comment.createdAt),
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
