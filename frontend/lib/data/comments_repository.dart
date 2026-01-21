import 'package:dio/dio.dart';
import 'api_client.dart';

class CommentItem {
  CommentItem({
    required this.id,
    required this.postId,
    required this.text,
    required this.createdAt,
    required this.authorId,
    required this.likeCount,
    required this.isLiked,
    required this.isBest,
  });

  final String id;
  final String postId;
  final String text;
  final DateTime createdAt;
  final String authorId;
  int likeCount;
  bool isLiked;

  /// ✅ 채택(베스트) 여부
  final bool isBest;

  factory CommentItem.fromJson(Map<String, dynamic> j, {required String postId}) {
    return CommentItem(
      id: (j['id'] ?? '').toString(),
      postId: postId,
      text: (j['content'] ?? j['text'] ?? '').toString(),
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      authorId: (j['userId'] ?? j['authorId'] ?? '').toString(),
      likeCount: (j['likeCount'] ?? 0) is int
          ? (j['likeCount'] ?? 0) as int
          : int.tryParse((j['likeCount'] ?? '0').toString()) ?? 0,
      isLiked: (j['likedByMe'] ?? j['isLiked'] ?? false) == true,
      isBest: (j['isBest'] ?? j['isAccepted'] ?? false) == true,
    );
  }
}

class AdoptedComment {
  AdoptedComment({
    required this.id,
    required this.content,
    required this.likeCount,
    required this.createdAt,
    required this.storyId,
    required this.storyTitle,
  });

  final String id;
  final String content;
  final int likeCount;
  final DateTime createdAt;
  final String storyId;
  

  /// ✅ 있을 수도/없을 수도 있는 값이라 UI에서 dynamic-safe로 처리합니다.
  final String storyTitle;

  factory AdoptedComment.fromJson(Map<String, dynamic> j) {
    final story = j['story'] as Map<String, dynamic>? ?? {};
    return AdoptedComment(
      id: j['id'].toString(),
      content: (j['content'] ?? '').toString(),
      likeCount: (j['likeCount'] ?? 0) is int
          ? (j['likeCount'] ?? 0) as int
          : int.tryParse((j['likeCount'] ?? '0').toString()) ?? 0,
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      storyId: (story['id'] ?? '').toString(),
      storyTitle: (story['title'] ?? '').toString(),
    );
  }
}

class CommentsRepository {
  CommentsRepository(this._client);
  final DataClient _client;
  Dio get _dio => _client.dio;

  /// GET /comments?storyId=xxx
  Future<List<CommentItem>> fetchComments(String postId) async {
    final res = await _dio.get('/comments', queryParameters: {'storyId': postId});
    final data = res.data;

    List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = (data['data'] as List?) ?? (data['items'] as List?) ?? (data['comments'] as List?) ?? [];
    } else {
      items = const [];
    }

    return items
        .whereType<Map>()
        .map((e) => CommentItem.fromJson(e.cast<String, dynamic>(), postId: postId))
        .toList();
  }

  /// POST /comments
  Future<CommentItem> addComment(String postId, String text) async {
    final res = await _dio.post('/comments', data: {'storyId': postId, 'content': text});
    final data = res.data;
    final item = (data is Map) ? data.cast<String, dynamic>() : <String, dynamic>{};
    return CommentItem.fromJson(item, postId: postId);
  }

  /// POST /comments/:id/like
  Future<void> toggleCommentLike(String commentId) async {
    await _dio.post('/comments/$commentId/like');
  }

  /// PATCH /comments/:id/adopt
  Future<void> acceptComment(String postId, String commentId) async {
    await _dio.patch('/comments/$commentId/adopt');
  }

  /// ✅ DELETE /comments/:id
  Future<void> deleteComment(String commentId) async {
    await _dio.delete('/comments/$commentId');
  }

  /// GET /comments/adopted/mine
  Future<List<AdoptedComment>> fetchMyAdoptedComments() async {
    final res = await _dio.get('/comments/adopted/mine');
    final data = res.data;

    List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = (data['data'] as List?) ?? (data['items'] as List?) ?? (data['comments'] as List?) ?? [];
    } else {
      items = const [];
    }

    return items.whereType<Map>().map((e) => AdoptedComment.fromJson(e.cast<String, dynamic>())).toList();
  }
}
