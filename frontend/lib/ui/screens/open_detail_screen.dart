import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/board_repository.dart';
import '../../data/comments_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/board_provider.dart';
import '../../providers/comments_provider.dart';

const _readableBodyFont = 'ChosunCentennial';

// ✅ Speaker texture for comment area (matches speaker panel)
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
  bool _postLiked = false;
  int _postLikeCount = 0;
  String? _initializedPostId;
  BoardPost? _cachedPost;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _ensureInitialized(BoardPost post, String currentUserId) {
    if (_initializedPostId == post.id) return;
    _initializedPostId = post.id;
    _postLikeCount = post.empathyCount;
    _postLiked = post.likedByMe;
    _acceptedCommentId = post.acceptedCommentId;
  }

  Future<void> _togglePostLike(String postId) async {
    // optimistic UI
    setState(() {
      _postLiked = !_postLiked;
      _postLikeCount += _postLiked ? 1 : -1;
      if (_postLikeCount < 0) _postLikeCount = 0;
    });
    await ref.read(boardControllerProvider.notifier).togglePostLike(postId);
  }

  Future<void> _submitComment(String postId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    FocusScope.of(context).unfocus();
    await ref.read(commentsProvider(postId).notifier).add(text);
  }

  Future<void> _showAdoptConfirmDialog(
    BuildContext context,
    String commentId,
    CommentsController commentsCtrl,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2520),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '위로 채택',
          style: TextStyle(
            color: Color(0xFFF2EBDD),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: const Text(
          '해당 위로를 채택하시겠습니까?\n채택은 취소할 수 없으며, 사연당 하나의 위로만 채택할 수 있습니다.',
          style: TextStyle(
            color: Color(0xCCD7CCB9),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(color: Color(0x99D7CCB9)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '채택',
              style: TextStyle(
                color: Color(0xFFF2EBDD),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await commentsCtrl.accept(commentId);
        await commentsCtrl.refresh();
        if (mounted) {
          ref.invalidate(boardPostProvider(widget.postId)); // 스토리 상세 갱신
          setState(() => _acceptedCommentId = commentId);
        }
      } catch (e) {
        if (!mounted) return;
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('409')
                  ? '이미 채택된 위로가 있습니다.'
                  : '채택에 실패했습니다.',
            ),
            backgroundColor: const Color(0xFFE25B5B),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(boardPostProvider(widget.postId));
    final commentsState = ref.watch(commentsProvider(widget.postId));
    final commentsCtrl = ref.read(commentsProvider(widget.postId).notifier);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    final valuePost = postAsync.value;
    if (valuePost != null) {
      _cachedPost = valuePost;
    }
    final post = _cachedPost;

    if (post == null) {
      if (postAsync.hasError) {
        return Center(
          child: Text(
            '주파수를 불러올 수 없어요. ${postAsync.error}',
            style: theme.textTheme.titleMedium,
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final currentUserId = authState.userIdLikeKey;
    _ensureInitialized(post, currentUserId);
    final isPostOwner = currentUserId.isNotEmpty &&
        post.authorId != null &&
        post.authorId == currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (widget.fromTheater) {
                          // Return to theater mode
                          context.pop();
                        } else if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/open');
                        }
                      },
                      customBorder: const StadiumBorder(),
                      child: Ink(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x24171411),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0x2ED7CCB9), width: 1),
                        ),
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
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ✅ Comment area with speaker texture background
            Expanded(
              child: Container(
                decoration: _speakerTextureDecoration(),
                child: Column(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final comments = commentsState.items;
                          final ordered =
                              _orderedComments(comments, _acceptedCommentId);
                          final acceptEnabled =
                              isPostOwner && _acceptedCommentId == null;
                          return ListView.separated(
                            padding: const EdgeInsets.only(top: 12, bottom: 12),
                          itemCount: ordered.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _PostDetailCard(
                                body: post.body,
                                isLiked: _postLiked,
                                likeCount: _postLikeCount,
                                onToggleLike: () => _togglePostLike(post.id),
                              );
                            }
                            final comment = ordered[index - 1];
                            final isAccepted =
                                comment.id == _acceptedCommentId;
                            return _CommentCard(
                              comment: comment,
                              isAccepted: isAccepted,
                              isPostOwner: isPostOwner,
                              onToggleLike: () =>
                                  commentsCtrl.toggleLike(comment.id),
                              onToggleAccept: acceptEnabled
                                  ? () => _showAdoptConfirmDialog(
                                        context,
                                        comment.id,
                                        commentsCtrl,
                                      )
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
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

  String _formatTime(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }

  List<CommentItem> _orderedComments(
      List<CommentItem> comments, String? acceptedId) {
    if (acceptedId == null) return List<CommentItem>.from(comments);
    final ordered = List<CommentItem>.from(comments);
    final index = ordered.indexWhere((comment) => comment.id == acceptedId);
    if (index <= 0) return ordered;
    final accepted = ordered.removeAt(index);
    ordered.insert(0, accepted);
    return ordered;
  }
}

class _PostDetailCard extends StatelessWidget {
  const _PostDetailCard({
    required this.body,
    required this.isLiked,
    required this.likeCount,
    required this.onToggleLike,
  });

  final String body;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = isLiked
        ? const Color(0xFFE25B5B)
        : const Color(0xFFD7CCB9).withValues(alpha: 0.80);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: _readableBodyFont,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: onToggleLike,
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: iconColor,
                    ),
                    padding: EdgeInsets.zero,
                    splashRadius: 22,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  likeCount.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: const Color(0xFFD7CCB9).withValues(alpha: 0.75),
                  ),
                ),
                const Spacer(),
              ],
            ),
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
    required this.isPostOwner,
    required this.onToggleLike,
    required this.onToggleAccept,
  });

  final CommentItem comment;
  final bool isAccepted;
  final bool isPostOwner;
  final VoidCallback onToggleLike;
  final VoidCallback? onToggleAccept;

  @override
  Widget build(BuildContext context) {
    final likeIcon = comment.isLiked ? Icons.favorite : Icons.favorite_border;
    final likeColor = comment.isLiked
        ? const Color(0xFFE25B5B)
        : const Color(0xFFD7CCB9).withValues(alpha: 0.80);
    final acceptIcon = isAccepted ? Icons.verified : Icons.verified_outlined;
    final acceptColor = isAccepted
        ? const Color(0xFFF2EBDD).withValues(alpha: 0.95)
        : const Color(0xFFD7CCB9).withValues(alpha: 0.70);

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0x1A171411),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1FD7CCB9), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: _readableBodyFont,
                            fontSize: 13,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (isPostOwner) ...[
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: onToggleLike,
                    icon: Icon(likeIcon, size: 18, color: likeColor),
                    padding: EdgeInsets.zero,
                    splashRadius: 22,
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: onToggleAccept,
                    icon: Icon(acceptIcon, size: 18, color: acceptColor),
                    padding: EdgeInsets.zero,
                    splashRadius: 22,
                  ),
                ),
              ] else
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: onToggleLike,
                    icon: Icon(likeIcon, size: 18, color: likeColor),
                    padding: EdgeInsets.zero,
                    splashRadius: 22,
                  ),
                ),
            ],
          ),
        ),
        if (isAccepted)
          Positioned(
            left: 16,
            bottom: 6,
            child: Container(
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0x24171411),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    size: 14,
                    color: const Color(0xFFF2EBDD).withValues(alpha: 0.92),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '채택됨',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xEBF2EBDD),
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
      height: 56,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0x24171411),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
              ),
              child: TextField(
                controller: controller,
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: '댓글을 남겨보세요',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Color(0xA6D7CCB9),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: onSend,
              icon: Icon(
                Icons.send,
                size: 18,
                color: const Color(0xFFD7CCB9).withValues(alpha: 0.85),
              ),
              padding: EdgeInsets.zero,
              splashRadius: 22,
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
      constraints: const BoxConstraints(maxWidth: 110),
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFD7CCB9).withValues(alpha: 0.92),
            fontFamily: _readableBodyFont,
          ),
        ),
      ),
    );
  }
}
