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
  });

  final String id;
  final String postId;
  final String text;
  final DateTime createdAt;
  final String? authorId;
  int likeCount;
  bool isLiked;

  factory CommentItem.fromJson(Map<String, dynamic> j) {
    return CommentItem(
      id: j['id'].toString(),
      postId: j['postId'].toString(),
      text: (j['content'] ?? j['body'] ?? j['text'] ?? '').toString(),
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      authorId: j['authorId']?.toString(),
      likeCount: (j['likeCount'] ?? 0) is int ? (j['likeCount'] ?? 0) as int : int.tryParse((j['likeCount'] ?? '0').toString()) ?? 0,
      isLiked: j['isLiked'] == true,
    );
  }
}

/// Adopted comment with associated story info
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

  /// 백엔드: GET /comments?storyId=xxx
  Future<List<CommentItem>> fetchComments(String postId) async {
    final res = await _dio.get('/comments', queryParameters: {'storyId': postId});
    final data = res.data;

    // 백엔드가 직접 배열로 응답하거나 {data: [...]} 형태일 수 있음
    List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = (data['data'] as List?) ??
          (data['items'] as List?) ??
          (data['comments'] as List?) ??
          [];
    } else {
      items = const [];
    }

    return items
        .whereType<Map>()
        .map((e) => CommentItem.fromJson({
              ...e.cast<String, dynamic>(),
              'postId': postId,
            }))
        .toList();
  }

  /// 백엔드: POST /comments {storyId, content}
  Future<CommentItem> addComment(String postId, String text) async {
    final res = await _dio.post('/comments', data: {
      'storyId': postId,
      'content': text,
    });
    final data = res.data;
    final item = (data is Map)
        ? data.cast<String, dynamic>()
        : <String, dynamic>{};
    return CommentItem.fromJson({...item, 'postId': postId});
  }

  /// 백엔드: POST /comments/:id/like
  Future<void> toggleCommentLike(String commentId) async {
    await _dio.post('/comments/$commentId/like');
  }

  /// 댓글 채택: PATCH /comments/:id/adopt
  /// - One-way (irreversible)
  /// - Only story owner can adopt
  /// - A story can have at most ONE adopted comment
  /// Throws on error (403: not owner, 409: already has adopted comment)
  Future<void> acceptComment(String postId, String commentId) async {
    await _dio.patch('/comments/$commentId/adopt');
  }

  /// 내가 작성하고 채택된 위로 목록: GET /comments/my/adopted
  Future<List<AdoptedComment>> fetchMyAdoptedComments() async {
    final res = await _dio.get('/comments/my/adopted');
    final data = res.data;

    List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = (data['data'] as List?) ??
          (data['items'] as List?) ??
          (data['comments'] as List?) ??
          [];
    } else {
      items = const [];
    }

    return items
        .whereType<Map>()
        .map((e) => AdoptedComment.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
