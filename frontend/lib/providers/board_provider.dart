import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/board_repository.dart';

final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  return MockBoardRepository();
});

class BoardState {
  const BoardState({
    required this.openPosts,
    required this.myPosts,
  });

  final List<BoardPost> openPosts;
  final List<BoardPost> myPosts;
}

class BoardController extends StateNotifier<BoardState> {
  BoardController(this._repository)
      : super(
          BoardState(
            openPosts: _repository.fetchOpen(),
            myPosts: _repository.fetchMine(),
          ),
        );

  final BoardRepository _repository;

  void refresh() {
    state = BoardState(
      openPosts: _repository.fetchOpen(),
      myPosts: _repository.fetchMine(),
    );
  }

  BoardPost submitStory({
    required String title,
    required String body,
    required List<String> tags,
    required bool publish,
  }) {
    final post = _repository.submitStory(
      title: title,
      body: body,
      tags: tags,
      publish: publish,
    );
    state = BoardState(
      openPosts: _repository.fetchOpen(),
      myPosts: _repository.fetchMine(),
    );
    return post;
  }

  BoardPost? findById(String id) => _repository.findById(id);
}

final boardControllerProvider =
    StateNotifierProvider<BoardController, BoardState>((ref) {
  final repo = ref.watch(boardRepositoryProvider);
  return BoardController(repo);
});

final boardPostProvider = Provider.family<BoardPost?, String>((ref, id) {
  final posts = ref.watch(boardControllerProvider).openPosts;
  for (final post in posts) {
    if (post.id == id) return post;
  }
  return null;
});

final myPostsProvider = Provider<List<BoardPost>>((ref) {
  return ref.watch(boardControllerProvider).myPosts;
});
