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
    this.isLoadingOpen = false,
    this.isLoadingMine = false,
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

  factory BoardState.initial() => const BoardState(openPosts: [], myPosts: []);
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

  

  Future<void> submitStory({
    required String title,
    required String body,
    required List<String> tags,
    required bool publish,
  }) async {
    await _repository.submitStory(
      title: title,
      body: body,
      tags: tags,
      publish: publish,
    );

    await refreshMine();
    if (publish) await refreshOpen();
  }

  Future<void> deleteStory(String storyId) async {
    await _repository.deleteStory(storyId);

    // optimistic local remove
    final openNext = state.openPosts.where((p) => p.id != storyId).toList(growable: false);
    final mineNext = state.myPosts.where((p) => p.id != storyId).toList(growable: false);
    state = state.copyWith(openPosts: openNext, myPosts: mineNext);

    // re-sync
    await refreshMine();
    await refreshOpen();
  }

  BoardPost? findById(String id) {
    for (final p in state.openPosts) {
      if (p.id == id) return p;
    }
    for (final p in state.myPosts) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> toggleStoryLike(String storyId) async {
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
      final updated = await _repository.toggleStoryLike(storyId);
      final open2 = [...state.openPosts];
      final idx2 = open2.indexWhere((e) => e.id == storyId);
      if (idx2 >= 0) open2[idx2] = updated;
      state = state.copyWith(openPosts: open2);
    } catch (_) {
      await refreshOpen();
    }
  }
}

final boardControllerProvider =
    StateNotifierProvider<BoardController, BoardState>((ref) {
  final repo = ref.watch(boardRepositoryProvider);
  return BoardController(repo);
});

final boardPostProvider = FutureProvider.family<BoardPost?, String>((ref, id) async {
  ref.watch(boardControllerProvider);
  final controller = ref.read(boardControllerProvider.notifier);
  return controller.findById(id) ?? await ref.read(boardRepositoryProvider).findById(id);
});

final myPostsProvider = Provider<List<BoardPost>>((ref) {
  // R7: "내가 공유한 글" 에는 isPublic == true 인 글만 표시
  return ref.watch(boardControllerProvider).myPosts.where((p) => p.isPublic).toList();
});
