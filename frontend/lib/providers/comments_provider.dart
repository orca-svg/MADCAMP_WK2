import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/comments_repository.dart';
import 'board_provider.dart';

final commentsRepositoryProvider = Provider<CommentsRepository>((ref) {
  final client = ref.watch(dataClientProvider);
  return CommentsRepository(client);
});

class CommentsState {
  const CommentsState({
    required this.items,
    this.isLoading = false,
  });

  final List<CommentItem> items;
  final bool isLoading;

  CommentsState copyWith({
    List<CommentItem>? items,
    bool? isLoading,
  }) {
    return CommentsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CommentsController extends StateNotifier<CommentsState> {
  CommentsController(this._repo, this.postId)
      : super(const CommentsState(items: [])) {
    refresh();
  }

  final CommentsRepository _repo;
  final String postId;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repo.fetchComments(postId);
      state = state.copyWith(items: items, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> add(String text) async {
    // optimistic: 임시 댓글 추가 후 refresh
    try {
      await _repo.addComment(postId, text);
      await refresh();
    } catch (_) {}
  }

  Future<void> toggleLike(String commentId) async {
    // optimistic
    final next = state.items.map((c) {
      if (c.id != commentId) return c;
      c.isLiked = !c.isLiked;
      c.likeCount += c.isLiked ? 1 : -1;
      if (c.likeCount < 0) c.likeCount = 0;
      return c;
    }).toList();
    state = state.copyWith(items: next);

    try {
      await _repo.toggleCommentLike(commentId);
    } catch (_) {
      await refresh();
    }
  }

  Future<void> accept(String commentId) async {
    // Propagate errors so UI can show appropriate message
    await _repo.acceptComment(postId, commentId);
    await refresh();
  }
}

final commentsProvider =
    StateNotifierProvider.family<CommentsController, CommentsState, String>((ref, postId) {
  final repo = ref.watch(commentsRepositoryProvider);
  return CommentsController(repo, postId);
});

/// Provider for user's adopted comments (comments they authored that were accepted)
final myAdoptedCommentsProvider = FutureProvider<List<AdoptedComment>>((ref) async {
  final repo = ref.watch(commentsRepositoryProvider);
  return repo.fetchMyAdoptedComments();
});
