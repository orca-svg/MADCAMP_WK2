// lib/data/api_models.dart
import 'package:flutter/foundation.dart';

DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  final s = v.toString();
  return DateTime.tryParse(s) ?? DateTime.now();
}

List<T> _asList<T>(dynamic v, T Function(dynamic) map) {
  if (v is List) return v.map(map).toList(growable: false);
  return const [];
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return <String, dynamic>{};
}

/// 백엔드 응답이
/// 1) List 그대로 올 수도 있고
/// 2) {data: [...]} 형태로 올 수도 있고
/// 3) {stories: [...]} 등으로 감쌀 수도 있어서 "유연 파싱"을 합니다.
List<Map<String, dynamic>> extractList(dynamic resData) {
  if (resData is List) {
    return resData.map(_asMap).toList(growable: false);
  }
  final m = _asMap(resData);
  for (final key in ['data', 'stories', 'items', 'result']) {
    final v = m[key];
    if (v is List) return v.map(_asMap).toList(growable: false);
  }
  return const [];
}

Map<String, dynamic> extractObject(dynamic resData) {
  final m = _asMap(resData);
  for (final key in ['data', 'story', 'comment', 'result']) {
    final v = m[key];
    if (v is Map) return _asMap(v);
  }
  return m;
}

class ApiStory {
  ApiStory({
    required this.id,
    required this.title,
    required this.content,
    required this.isPublic,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.userId,
    required this.tags,
    this.likedByMe,
    this.authorNickname,
    this.acceptedCommentId,
  });

  final String id;
  final String title;
  final String content;
  final bool isPublic;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final String userId;
  final List<String> tags;

  /// 백엔드가 내려주면 사용(없으면 null)
  final bool? likedByMe;

  /// 백엔드가 user join 해서 내려주면 사용(없으면 null)
  final String? authorNickname;

  /// 채택된 댓글 ID (백엔드 isBest=true인 댓글)
  final String? acceptedCommentId;

  factory ApiStory.fromJson(Map<String, dynamic> j) {
    // tags: ["#불안 😰"] / [{name:"..."}] 둘 다 커버
    List<String> tags = const [];
    final rawTags = j['tags'];
    if (rawTags is List) {
      tags = rawTags.map((e) {
        if (e is String) return e;
        final m = _asMap(e);
        final name = (m['name'] ?? m['label'] ?? '').toString();
        return name;
      }).where((s) => s.trim().isNotEmpty).toList(growable: false);
    }

    final user = _asMap(j['user']);
    // 백엔드가 isLiked로 내려주는 경우도 커버
    final likedByMe = j['likedByMe'] is bool
        ? j['likedByMe'] as bool
        : (j['isLiked'] is bool ? j['isLiked'] as bool : null);

    return ApiStory(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      content: (j['content'] ?? j['body'] ?? '').toString(),
      isPublic: (j['isPublic'] ?? j['public'] ?? true) == true,
      likeCount: (j['likeCount'] ?? j['likes'] ?? 0) is int
          ? (j['likeCount'] ?? j['likes'] ?? 0) as int
          : int.tryParse((j['likeCount'] ?? j['likes'] ?? '0').toString()) ?? 0,
      commentCount: (j['commentCount'] ?? 0) is int
          ? (j['commentCount'] ?? 0) as int
          : int.tryParse((j['commentCount'] ?? '0').toString()) ?? 0,
      createdAt: _parseDate(j['createdAt']),
      userId: (j['userId'] ?? user['id'] ?? '').toString(),
      tags: tags,
      likedByMe: likedByMe,
      authorNickname: (user['nickname'] ?? user['name'])?.toString(),
      acceptedCommentId: j['acceptedCommentId']?.toString(),
    );
  }
}

class ApiComment {
  ApiComment({
    required this.id,
    required this.content,
    required this.likeCount,
    required this.isBest,
    required this.createdAt,
    required this.userId,
    this.authorNickname,
  });

  final String id;
  final String content;
  final int likeCount;
  final bool isBest;
  final DateTime createdAt;
  final String userId;
  final String? authorNickname;

  factory ApiComment.fromJson(Map<String, dynamic> j) {
    final user = _asMap(j['user']);
    return ApiComment(
      id: (j['id'] ?? '').toString(),
      content: (j['content'] ?? j['text'] ?? '').toString(),
      likeCount: (j['likeCount'] ?? 0) is int
          ? (j['likeCount'] ?? 0) as int
          : int.tryParse((j['likeCount'] ?? '0').toString()) ?? 0,
      isBest: (j['isBest'] ?? false) == true,
      createdAt: _parseDate(j['createdAt']),
      userId: (j['userId'] ?? user['id'] ?? '').toString(),
      authorNickname: (user['nickname'] ?? user['name'])?.toString(),
    );
  }
}
