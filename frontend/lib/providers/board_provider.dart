// lib/providers/board_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/board_repository.dart';
import 'prefs_provider.dart';

final dataClientProvider = Provider<DataClient>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return DataClient(prefs: prefs);
});

final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  final client = ref.watch(dataClientProvider);
  return ApiBoardRepository(client);
});

class BoardState {
  const BoardState({
    required this.openPosts,
    required this.myPosts,
    required this.isLoadingOpen,
    required this.isLoadingMine,
  });

  final List<BoardPost> openPosts;
  final List<BoardPost> myPosts;
  final bool isLoadingOpen;
  final bool isLoadingMine;

  BoardState copyWith({
    List<BoardPost>? openPosts,
    List<BoardPost>? myPosts,
    bool? isLoadingOpen,
    bool? isLoadingMine,
  }) {
    return BoardState(
      openPosts: openPosts ?? this.openPosts,
      myPosts: myPosts ?? this.myPosts,
      isLoadingOpen: isLoadingOpen ?? this.isLoadingOpen,
      isLoadingMine: isLoadingMine ?? this.isLoadingMine,
    );
  }

  factory BoardState.initial() => const BoardState(
        openPosts: [],
        myPosts: [],
        isLoadingOpen: false,
        isLoadingMine: false,
      );
}

class BoardController extends StateNotifier<BoardState> {
  BoardController(this._repository) : super(BoardState.initial());

  final BoardRepository _repository;

  Future<void> refreshOpen() async {
    state = state.copyWith(isLoadingOpen: true);
    try {
      final open = await _repository.fetchOpen();
      state = state.copyWith(openPosts: open, isLoadingOpen: false);
    } catch (_) {
      state = state.copyWith(isLoadingOpen: false);
      rethrow;
    }
  }

  Future<void> refreshMine() async {
    state = state.copyWith(isLoadingMine: true);
    try {
      final mine = await _repository.fetchMine();
      state = state.copyWith(myPosts: mine, isLoadingMine: false);
    } catch (_) {
      state = state.copyWith(isLoadingMine: false);
      rethrow;
    }
  }

  Future<BoardPost> submitStory({
    required String title,
    required String body,
    required List<String> tags,
    required bool publish,
  }) async {
    final created = await _repository.submitStory(
      title: title,
      body: body,
      tags: tags,
      publish: publish,
    );

    // myPosts 갱신
    await refreshMine();

    // 공개로 발행한 경우 open도 갱신(또는 optimistic insert)
    if (publish) {
      await refreshOpen();
    }
    return created;
  }

  Future<BoardPost?> findById(String id) async {
    // 우선 캐시에서 찾고, 없으면 API로
    for (final p in state.openPosts) {
      if (p.id == id) return p;
    }
    for (final p in state.myPosts) {
      if (p.id == id) return p;
    }
    return _repository.findById(id);
  }

  Future<void> toggleStoryLike(String storyId) async {
    // optimistic: openPosts에서 즉시 반영(UX)
    final open = [...state.openPosts];
    final idx = open.indexWhere((e) => e.id == storyId);
    if (idx >= 0) {
      final p = open[idx];
      final nextLiked = !p.likedByMe;
      final nextCount = (p.likeCount + (nextLiked ? 1 : -1)).clamp(0, 1 << 30);
      open[idx] = p.copyWith(likedByMe: nextLiked, likeCount: nextCount);
      state = state.copyWith(openPosts: open);
    }

    try {
      final refreshed = await _repository.toggleStoryLike(storyId);

      // 서버 값으로 정합 맞추기(있으면)
      final open2 = [...state.openPosts];
      final idx2 = open2.indexWhere((e) => e.id == storyId);
      if (idx2 >= 0) {
        open2[idx2] = open2[idx2].copyWith(
          likedByMe: refreshed.likedByMe,
          likeCount: refreshed.likeCount,
        );
      }
      state = state.copyWith(openPosts: open2);
    } catch (_) {
      // 실패 시 전체 새로고침으로 복구
      await refreshOpen();
      rethrow;
    }
  }

  /// Alias for toggleStoryLike (UI compatibility)
  Future<void> togglePostLike(String postId) => toggleStoryLike(postId);

  // 댓글은 detail screen에서 repository 직접 사용해도 되지만,
  // 일단 컨트롤러에서 다루기 쉽게 provider로 노출합니다.
  BoardRepository get repository => _repository;
}

final boardControllerProvider =
    StateNotifierProvider<BoardController, BoardState>((ref) {
  final repo = ref.watch(boardRepositoryProvider);
  return BoardController(repo);
});

final boardPostProvider = FutureProvider.family<BoardPost?, String>((ref, id) async {
  final controller = ref.read(boardControllerProvider.notifier);
  return controller.findById(id);
});

final myPostsProvider = Provider<List<BoardPost>>((ref) {
  return ref.watch(boardControllerProvider).myPosts;
});
