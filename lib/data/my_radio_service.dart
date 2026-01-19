import 'package:flutter/foundation.dart';

import 'board_repository.dart';

class MyRadioService {
  MyRadioService(this._repository);

  final BoardRepository _repository;

  // TODO: Backend API 연동 (fetchMyStories)
  Future<List<BoardPost>> fetchMyStories() async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    return _repository.fetchMine();
  }

  // TODO: Backend API 연동 (fetchAcceptedComforts)
  Future<List<BoardPost>> fetchAcceptedComforts() async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    return _repository
        .fetchMine()
        .where((post) => post.acceptedCommentId != null)
        .toList(growable: false);
  }

  // TODO: Backend API 연동 (fetchBookmarks)
  Future<List<BoardPost>> fetchBookmarks() async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    // Placeholder: return open posts until backend supports bookmark IDs.
    return _repository.fetchOpen();
  }
}
