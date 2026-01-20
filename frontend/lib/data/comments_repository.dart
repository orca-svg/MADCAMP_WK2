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

  /// 댓글 채택 (백엔드에 별도 엔드포인트 없을 수 있음)
  /// 향후 PATCH /comments/:id {isBest: true} 등으로 확장 필요
  Future<void> acceptComment(String postId, String commentId) async {
    // 백엔드에 accept 엔드포인트가 없으면 무시
    // 추후 백엔드 구현 후 활성화
    try {
      await _dio.patch('/comments/$commentId', data: {'isBest': true});
    } catch (_) {
      // endpoint 없을 경우 무시 (프론트에서만 표시)
    }
  }
}
