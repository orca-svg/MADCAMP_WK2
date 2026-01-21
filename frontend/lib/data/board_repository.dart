// lib/data/board_repository.dart
import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_models.dart';

class BoardPost {
  const BoardPost({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.createdAt,
    required this.isMine,
    required this.authorId,
    this.likeCount = 0,
    this.likedByMe = false,
    this.acceptedCommentId,
  });

  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime createdAt;

  /// 프론트에서 "내 글" 여부 표시용
  final bool isMine;

  final String? authorId;

  /// 백엔드 likeCount
  final int likeCount;

  /// 백엔드가 내려주면 반영, 없으면 토글 후 optimistic 업데이트
  final bool likedByMe;

  /// 채택된 댓글 ID (백엔드에서 isBest=true인 댓글)
  final String? acceptedCommentId;

  /// empathyCount는 likeCount의 alias (UI 호환용)
  int get empathyCount => likeCount;

  /// likedUserIds 대신 likedByMe로 현재 사용자 좋아요 여부만 판단
  /// 하위 호환을 위해 빈 리스트 또는 현재 사용자 포함 리스트 반환
  List<String> get likedUserIds => likedByMe ? ['_current_user_'] : [];

  BoardPost copyWith({
    int? likeCount,
    bool? likedByMe,
    String? acceptedCommentId,
  }) {
    return BoardPost(
      id: id,
      title: title,
      body: body,
      tags: tags,
      createdAt: createdAt,
      isMine: isMine,
      authorId: authorId,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      acceptedCommentId: acceptedCommentId ?? this.acceptedCommentId,
    );
  }
}

abstract class BoardRepository {
  Future<List<BoardPost>> fetchOpen();
  Future<List<BoardPost>> fetchMine();
  Future<BoardPost?> findById(String id);

  Future<BoardPost> submitStory({
    required String title,
    required String body,
    required List<String> tags,
    required bool publish,
  });

  Future<BoardPost> toggleStoryLike(String storyId);

  Future<List<ApiComment>> fetchComments(String storyId);
  Future<ApiComment> createComment({
    required String storyId,
    required String content,
  });
  Future<ApiComment> toggleCommentLike(String commentId);
}

/// ✅ API Repository
class ApiBoardRepository implements BoardRepository {
  ApiBoardRepository(this._client);

  final DataClient _client;

  Dio get _dio => _client.dio;

  String _userIdFromMe(Map<String, dynamic>? me) {
    if (me == null) return '';
    return (me['id'] ?? '').toString();
  }

  BoardPost _toBoardPost(ApiStory s, {required String myUserId, String? acceptedCommentId}) {
    final isMine = myUserId.isNotEmpty && s.userId == myUserId;
    return BoardPost(
      id: s.id,
      title: s.title,
      body: s.content,
      tags: s.tags,
      createdAt: s.createdAt,
      isMine: isMine,
      authorId: s.userId,
      likeCount: s.likeCount,
      likedByMe: s.likedByMe ?? false,
      acceptedCommentId: acceptedCommentId ?? s.acceptedCommentId,
    );
  }

  @override
  Future<List<BoardPost>> fetchOpen() async {
    final me = await _client.getMe();
    final myUserId = _userIdFromMe(me['user'] as Map<String, dynamic>?);

    final res = await _dio.get('/stories');
    final list = extractList(res.data);
    final stories = list.map(ApiStory.fromJson).toList(growable: false);

    // 공개만(혹시 백엔드가 전체 주면 필터)
    final publicOnly = stories.where((s) => s.isPublic).toList(growable: false);

    return publicOnly.map((s) => _toBoardPost(s, myUserId: myUserId)).toList();
  }

  @override
  Future<List<BoardPost>> fetchMine() async {
    final me = await _client.getMe();
    final myUserId = _userIdFromMe(me['user'] as Map<String, dynamic>?);

    // 백엔드에 "내 글" endpoint가 있는지 불명확해서:
    // 1) /stories?mine=true 시도
    // 2) 실패하면 /stories 전체에서 userId로 필터
    try {
      final res = await _dio.get('/stories', queryParameters: {'mine': true});
      final list = extractList(res.data);
      final stories = list.map(ApiStory.fromJson).toList(growable: false);
      return stories.map((s) => _toBoardPost(s, myUserId: myUserId)).toList();
    } catch (_) {
      final open = await fetchOpen();
      return open.where((p) => p.authorId == myUserId).toList(growable: false);
    }
  }

  @override
  Future<BoardPost?> findById(String id) async {
    final me = await _client.getMe();
    final myUserId = _userIdFromMe(me['user'] as Map<String, dynamic>?);

    final res = await _dio.get('/stories/$id');
    final obj = extractObject(res.data);
    final story = ApiStory.fromJson(obj);
    return _toBoardPost(story, myUserId: myUserId);
  }

  @override
  Future<BoardPost> submitStory({
    required String title,
    required String body,
    required List<String> tags,
    required bool publish,
  }) async {
    final me = await _client.getMe();
    final myUserId = _userIdFromMe(me['user'] as Map<String, dynamic>?);

    final res = await _dio.post('/stories', data: {
      'title': title.isEmpty ? '새로운 사연' : title,
      'content': body,
      'isPublic': publish,
      'tags': tags,
    });

    final obj = extractObject(res.data);
    final story = ApiStory.fromJson(obj);
    return _toBoardPost(story, myUserId: myUserId);
  }

  @override
  Future<BoardPost> toggleStoryLike(String storyId) async {
    // 토글 endpoint
    final res = await _dio.post('/stories/$storyId/like');
    // 백엔드가 story를 다시 내려주면 반영
    try {
      final obj = extractObject(res.data);
      final liked = obj['liked'];
      final likeCountValue = obj['likeCount'];
      if (liked is bool && likeCountValue != null) {
        final parsedCount = likeCountValue is int
            ? likeCountValue
            : int.tryParse(likeCountValue.toString()) ?? 0;
        return BoardPost(
          id: storyId,
          title: '',
          body: '',
          tags: const [],
          createdAt: DateTime.now(),
          isMine: false,
          authorId: null,
          likeCount: parsedCount,
          likedByMe: liked,
        );
      }
      if (obj['id'] == null || obj['id'].toString().isEmpty) {
        throw StateError('Missing story payload');
      }
      final s = ApiStory.fromJson(obj);
      final me = await _client.getMe();
      final myUserId = _userIdFromMe(me['user'] as Map<String, dynamic>?);
      return _toBoardPost(s, myUserId: myUserId);
    } catch (_) {
      // 내려주는 게 없으면 detail 재조회
      final refreshed = await findById(storyId);
      if (refreshed == null) {
        // fallback
        return BoardPost(
          id: storyId,
          title: '',
          body: '',
          tags: const [],
          createdAt: DateTime.now(),
          isMine: false,
          authorId: null,
        );
      }
      return refreshed;
    }
  }

  @override
  Future<List<ApiComment>> fetchComments(String storyId) async {
    // swagger상 "Get comments by story" -> 보통 query param
    final res = await _dio.get('/comments', queryParameters: {'storyId': storyId});
    final list = extractList(res.data);
    return list.map(ApiComment.fromJson).toList(growable: false);
  }

  @override
  Future<ApiComment> createComment({
    required String storyId,
    required String content,
  }) async {
    final res = await _dio.post('/comments', data: {
      'storyId': storyId,
      'content': content,
    });
    final obj = extractObject(res.data);
    return ApiComment.fromJson(obj);
  }

  @override
  Future<ApiComment> toggleCommentLike(String commentId) async {
    final res = await _dio.post('/comments/$commentId/like');
    try {
      final obj = extractObject(res.data);
      return ApiComment.fromJson(obj);
    } catch (_) {
      // 좋아요 후 comment를 내려주지 않는다면: 일단 다시 목록을 받아서 찾는 방식이 필요
      // (이 부분은 백엔드 응답 확인 후 확정 가능)
      rethrow;
    }
  }
}
