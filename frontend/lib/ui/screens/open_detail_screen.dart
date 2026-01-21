import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../data/board_repository.dart';
import '../../data/comments_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/board_provider.dart';
import '../../providers/comments_provider.dart';

const _readableBodyFont = 'ChosunCentennial';

// ✅ Speaker texture for comment area (matches speaker panel)
// const String _speakerTexturePath = 'assets/textures/fabric_grille.png';
// const Color _speakerBase = Color(0xFF171411);
String _fmtDateTime(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}.${two(dt.month)}.${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}
// BoxDecoration _speakerTextureDecoration() {
//   return const BoxDecoration(
//     color: _speakerBase,
//     image: DecorationImage(
//       image: AssetImage(_speakerTexturePath),
//       fit: BoxFit.cover,
//       opacity: 0.20,
//     ),
//   );
// }

class OpenDetailScreen extends ConsumerStatefulWidget {
  const OpenDetailScreen({
    super.key,
    required this.postId,
    this.fromTheater = false,
  });

  final String postId;
  final bool fromTheater;

  @override
  ConsumerState<OpenDetailScreen> createState() => _OpenDetailScreenState();
}

class _OpenDetailScreenState extends ConsumerState<OpenDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  String? _acceptedCommentId;
  String? _initializedPostId;

  void _ensureInitialized(BoardPost post) {
    if (_initializedPostId == post.id) return;
    _initializedPostId = post.id;
    _acceptedCommentId = post.acceptedCommentId;
  }

  Future<void> _showAdoptConfirmDialog(
    BuildContext context,
    String commentId,
    CommentsController commentsCtrl,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        content: _DialogPanel(
          title: '해당 위로를 채택하시겠습니까?',
          body: '채택은 취소할 수 없으며, 사연당 하나의 위로만 채택할 수 있습니다.',
          confirmLabel: '채택',
          destructive: false,
          onCancel: () => Navigator.of(ctx).pop(false),
          onConfirm: () => Navigator.of(ctx).pop(true),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await commentsCtrl.accept(commentId);
      if (!mounted) return;
      setState(() => _acceptedCommentId = commentId);
      ref.invalidate(boardPostProvider(widget.postId));
      await commentsCtrl.refresh();
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      if (status == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 채택된 위로가 있어요.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('채택에 실패했어요. 잠시 후 다시 시도해 주세요.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('채택에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _showDeleteStoryConfirmDialog(
    BuildContext context, {
    required BoardController boardCtrl,
    required String storyId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        content: _DialogPanel(
          title: '사연을 삭제할까요?',
          body: '삭제하면 이 사연에 달린 위로(댓글)도 함께 삭제됩니다.',
          destructiveLabel: '삭제하기',
          onCancel: () => Navigator.of(ctx).pop(false),
          onConfirm: () => Navigator.of(ctx).pop(true),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await boardCtrl.deleteStory(storyId);

      if (mounted) {
        ref.invalidate(boardPostProvider(storyId));
        ref.invalidate(commentsProvider(storyId));
      }

      if (!mounted) return;
      if (widget.fromTheater) {
        context.pop();
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/open');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사연 삭제에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _showDeleteCommentConfirmDialog(
    BuildContext context, {
    required CommentsController commentsCtrl,
    required String commentId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        content: _DialogPanel(
          title: '위로를 삭제할까요?',
          body: null,
          destructiveLabel: '삭제',
          onCancel: () => Navigator.of(ctx).pop(false),
          onConfirm: () => Navigator.of(ctx).pop(true),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await commentsCtrl.deleteComment(commentId);
      await commentsCtrl.refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위로 삭제에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  List<CommentItem> _orderedComments(List<CommentItem> items, String? acceptedId) {
    if (acceptedId == null) return items;
    final accepted = items.where((c) => c.id == acceptedId).toList(growable: false);
    final others = items.where((c) => c.id != acceptedId).toList(growable: false);
    return [...accepted, ...others];
  }

  Future<void> _submitComment(String postId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    final ctrl = ref.read(commentsProvider(postId).notifier);
    await ctrl.add(text);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(boardPostProvider(widget.postId));
    final boardCtrl = ref.read(boardControllerProvider.notifier);
    final commentsState = ref.watch(commentsProvider(widget.postId));
    final commentsCtrl = ref.read(commentsProvider(widget.postId).notifier);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    final post = postAsync.valueOrNull;
    if (post == null) {
      if (postAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Text(
          '사연을 불러올 수 없어요.',
          style: theme.textTheme.titleMedium,
        ),
      );
    }

    _ensureInitialized(post);

    final currentUserId = authState.userIdLikeKey;
    final isPostOwner = (post.authorId != null && post.authorId == currentUserId) || post.isMine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ 상단: 목록으로/극장으로 + (작성자만) 사연 삭제
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (widget.fromTheater) {
                              context.pop();
                            } else {
                              context.pop();
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_left,
                              size: 18,
                              color: const Color(0xFFD7CCB9).withValues(alpha: 0.85),
                            ),
                            Text(
                              widget.fromTheater ? '극장으로' : '목록으로',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFD7CCB9).withValues(alpha: 0.90),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),
                  ),
                  if (isPostOwner)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        foregroundColor: const Color(0xFFF2EBDD),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: _readableBodyFont,
                        ),
                      ),
                    onPressed: () => _showDeleteStoryConfirmDialog(
                        context,
                        boardCtrl: boardCtrl,
                        storyId: post.id,
                      ),
                      child: const Text('사연 삭제'),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // ✅ 제목 (좌측 10px 여백)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  post.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: _readableBodyFont,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFF2EBDD),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ✅ 태그 (좌측 10px 여백)
              if (post.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: post.tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x1A171411),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0x1FD7CCB9), width: 1),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontFamily: _readableBodyFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD7CCB9),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 10),

              // ✅ 본문 (좌측 10px 여백)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  post.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: _readableBodyFont,
                    fontSize: 14,
                    height: 1.35,
                    color: const Color(0xFFF2EBDD).withValues(alpha: 0.95),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ✅ 하단 row: 게시 시간(작게) + 공감(우측)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fmtDateTime(post.createdAt),
                        style: const TextStyle(
                          fontFamily: _readableBodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xCCD7CCB9),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          onPressed: () async {
                            try {
                              await ref.read(boardControllerProvider.notifier).toggleStoryLike(post.id);
                            } catch (_) {}
                          },
                          icon: Icon(
                            post.likedByMe ? Icons.favorite : Icons.favorite_border,
                            color: post.likedByMe ? const Color.fromARGB(255, 242, 76, 76) : const Color(0xFFD7CCB9),
                            size: 18,
                          ),
                        ),
                        Text(
                          '${post.likeCount}',
                          style: const TextStyle(
                            fontFamily: _readableBodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF2EBDD),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
const SizedBox(height: 8),

        Expanded(
          child: InkWell(
            child: Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final comments = commentsState.items;
                      final ordered = _orderedComments(comments, _acceptedCommentId);
                      if (_acceptedCommentId == null) {
                        final best = comments.where((c) => c.isBest).toList();
                        if (best.isNotEmpty) _acceptedCommentId = best.first.id;
                      }
                      final acceptEnabled = isPostOwner && _acceptedCommentId == null;

                      if (commentsState.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (ordered.isEmpty) {
                        return const Center(
                          child: Text(
                            '아직 위로가 없어요.',
                            style: TextStyle(
                              color: Color(0xCCD7CCB9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        itemCount: ordered.length,
                        itemBuilder: (context, index) {
                          final comment = ordered[index];
                          final isAccepted = comment.id == _acceptedCommentId;
                          final canDelete = isPostOwner || comment.authorId == currentUserId;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CommentCard(
                              comment: comment,
                              isAccepted: isAccepted,
                              canAdopt: acceptEnabled,
                              canDelete: canDelete,
                              onToggleLike: () => commentsCtrl.toggleLike(comment.id),
                              onToggleAccept: acceptEnabled
                                  ? () => _showAdoptConfirmDialog(context, comment.id, commentsCtrl)
                                  : null,
                              onDelete: () => _showDeleteCommentConfirmDialog(
                                context,
                                commentsCtrl: commentsCtrl,
                                commentId: comment.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: _CommentInputBar(
                    controller: _commentController,
                    onSend: () => _submitComment(post.id),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogPanel extends StatelessWidget {
  const _DialogPanel({
    required this.title,
    required this.onCancel,
    required this.onConfirm,
    this.body,
    this.confirmLabel,
    this.destructiveLabel,
    this.destructive = true,
  });

  final String title;
  final String? body;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String? confirmLabel;
  final String? destructiveLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final label = destructiveLabel ?? confirmLabel ?? '확인';
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: const Color(0x1A171411),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1FD7CCB9), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF2EBDD),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 10),
            Text(
              body!,
              style: const TextStyle(
                color: Color(0xCCD7CCB9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: const Text('취소', style: TextStyle(color: Color(0x99D7CCB9))),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onConfirm,
                child: Text(
                  label,
                  style: TextStyle(
                    color: destructive ? const Color(0xFFE25B5B) : const Color(0xFFF2EBDD),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.isAccepted,
    required this.canAdopt,
    required this.canDelete,
    required this.onToggleLike,
    required this.onToggleAccept,
    required this.onDelete,
  });

  final CommentItem comment;
  final bool isAccepted;
  final bool canAdopt;
  final bool canDelete;
  final VoidCallback onToggleLike;
  final VoidCallback? onToggleAccept;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0x1A171411),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1FD7CCB9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 본문 + (권한) 채택/삭제 버튼(우측 밀착, 작은 크기)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  comment.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: _readableBodyFont,
                    fontSize: 13,
                    height: 1.35,
                    color: const Color(0xFFF2EBDD).withValues(alpha: 0.95),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isAccepted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x1AF2C94C),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x33F2C94C)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Color(0xFFF2C94C)),
                      SizedBox(width: 4),
                      Text(
                        '채택됨',
                        style: TextStyle(
                          fontFamily: _readableBodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF2C94C),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (canAdopt)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFFF2EBDD),
                      textStyle: const TextStyle(
                        fontFamily: _readableBodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: onToggleAccept,
                    child: const Text('채택'),
                  ),
                if (canDelete)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFFF2EBDD),
                      textStyle: const TextStyle(
                        fontFamily: _readableBodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: onDelete,
                    child: const Text('삭제'),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // ✅ 공감(우측) - 기존 크기 유지
          Row(
            children: [
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onToggleLike,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    icon: Icon(
                      comment.isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: comment.isLiked ? const Color(0xFFF2C94C) : const Color(0xFFD7CCB9),
                    ),
                  ),
                  Text(
                    '${comment.likeCount}',
                   style: const TextStyle(
                      fontFamily: _readableBodyFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF2EBDD),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ✅ 작성 시간(작게)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _fmtDateTime(comment.createdAt),
              style: const TextStyle(
                fontFamily: _readableBodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xCCD7CCB9),
              ),
            ),
          ),
        ],
      ),
    );
   }
}

class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      decoration: const BoxDecoration(
        color: Color(0x1A171411),
        border: Border(top: BorderSide(color: Color(0x1FD7CCB9), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Color(0xFFF2EBDD),
                fontFamily: _readableBodyFont,
              ),
              decoration: InputDecoration(
                hintText: '위로를 남겨주세요…',
                hintStyle: const TextStyle(color: Color(0xA6D7CCB9)),
                filled: true,
                fillColor: const Color(0x1A171411),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0x1FD7CCB9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0x1FD7CCB9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0x2ED7CCB9)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSend,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0x24171411),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: const Color(0xFFD7CCB9).withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
