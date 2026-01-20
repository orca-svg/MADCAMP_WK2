import 'board_repository.dart';

class MyRadioService {
  MyRadioService(this._repository);

  final BoardRepository _repository;

  Future<List<BoardPost>> fetchMyStories() async {
    return _repository.fetchMine();
  }

  Future<List<BoardPost>> fetchAcceptedComforts() async {
    final mine = await _repository.fetchMine();
    return mine
        .where((post) => post.acceptedCommentId != null)
        .toList(growable: false);
  }

  Future<List<BoardPost>> fetchBookmarks() async {
    // Placeholder: return open posts until backend supports bookmark IDs.
    return _repository.fetchOpen();
  }
}
