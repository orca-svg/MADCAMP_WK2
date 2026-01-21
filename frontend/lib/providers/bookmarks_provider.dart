import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_client.dart';
import 'auth_provider.dart';
import 'board_provider.dart';
import 'prefs_provider.dart';

/// Local metadata for a bookmarked advice.
class BookmarkMetadata {
  const BookmarkMetadata({
    required this.adviceId,
    required this.content,
    required this.bookmarkedAt,
  });

  final String adviceId;
  final String content;
  final DateTime bookmarkedAt;

  Map<String, dynamic> toJson() => {
        'adviceId': adviceId,
        'content': content,
        'bookmarkedAt': bookmarkedAt.toIso8601String(),
      };

  factory BookmarkMetadata.fromJson(Map<String, dynamic> json) {
    return BookmarkMetadata(
      adviceId: json['adviceId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      bookmarkedAt: DateTime.tryParse(json['bookmarkedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

const _metadataPrefsKey = 'bookmark_metadata_v1';

class BookmarksController extends StateNotifier<Set<String>> {
  BookmarksController(this._ref, this._client, this._prefs) : super(<String>{}) {
    _loadLocalMetadata();
    _bindAuth();
  }

  final Ref _ref;
  final DataClient _client;
  final SharedPreferences _prefs;
  Dio get _dio => _client.dio;

  /// Local metadata map: adviceId -> BookmarkMetadata
  Map<String, BookmarkMetadata> _metadata = {};

  void _loadLocalMetadata() {
    final raw = _prefs.getString(_metadataPrefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final m = BookmarkMetadata.fromJson(item);
          if (m.adviceId.isNotEmpty) {
            _metadata[m.adviceId] = m;
          }
        }
      }
    } catch (e) {
      debugPrint('bookmarks _loadLocalMetadata error=$e');
    }
  }

  Future<void> _saveLocalMetadata() async {
    final list = _metadata.values.map((m) => m.toJson()).toList();
    await _prefs.setString(_metadataPrefsKey, jsonEncode(list));
  }

  /// Returns sorted list of metadata (newest first).
  /// Only includes items that exist in current state (synced with backend).
  List<BookmarkMetadata> getMetadataList() {
    final result = <BookmarkMetadata>[];
    for (final id in state) {
      final m = _metadata[id];
      if (m != null) {
        result.add(m);
      } else {
        // Fallback for bookmarks without local metadata
        result.add(BookmarkMetadata(
          adviceId: id,
          content: '',
          bookmarkedAt: DateTime.now(),
        ));
      }
    }
    result.sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
    return result;
  }

  /// Get metadata for a specific advice ID.
  BookmarkMetadata? getMetadata(String adviceId) => _metadata[adviceId];

  void _bindAuth() {
    _ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isSignedIn && !next.isLoading) {
        refresh();
      } else {
        state = <String>{};
      }
    });

    final auth = _ref.read(authProvider);
    if (auth.isSignedIn && !auth.isLoading) {
      refresh();
    }
  }

  bool isBookmarked(String adviceId) => state.contains(adviceId);

  Future<void> refresh() async {
    try {
      debugPrint('bookmarks refresh baseUrl=${_client.dio.options.baseUrl}');
      final res = await _dio.get('/bookmarks');
      debugPrint('bookmarks refresh response=${res.data}');
      final data = res.data;
      final items = data is List
          ? data
          : (data is Map ? (data['data'] as List? ?? []) : <dynamic>[]);
      final ids = items
          .whereType<Map>()
          .map((e) => e['adviceId']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      state = ids;
    } catch (_) {
      // Ignore errors; keep current state.
    }
  }

  /// Toggle bookmark. When adding, pass [content] to store metadata locally.
  Future<void> toggle(String adviceId, {String? content}) async {
    final next = Set<String>.from(state);
    final isRemoving = next.contains(adviceId);
    if (isRemoving) {
      next.remove(adviceId);
      _metadata.remove(adviceId);
      _saveLocalMetadata();
    } else {
      next.add(adviceId);
      // Store metadata locally when adding
      if (content != null && content.isNotEmpty) {
        _metadata[adviceId] = BookmarkMetadata(
          adviceId: adviceId,
          content: content,
          bookmarkedAt: DateTime.now(),
        );
        _saveLocalMetadata();
      }
    }
    state = next;

    try {
      if (isRemoving) {
        await _dio.delete('/bookmarks', queryParameters: {'adviceId': adviceId});
      } else {
        await _dio.post('/bookmarks', data: {'adviceId': adviceId});
      }
    } on DioException catch (e) {
      debugPrint(
        'bookmarks toggle error status=${e.response?.statusCode} data=${e.response?.data}',
      );
      await refresh();
    } catch (e) {
      debugPrint('bookmarks toggle error=$e');
      await refresh();
    }
  }

  /// Remove bookmark (explicit removal, used from list screen).
  Future<void> remove(String adviceId) async {
    if (!state.contains(adviceId)) return;
    await toggle(adviceId);
  }

  void clear() => state = <String>{};
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksController, Set<String>>((ref) {
  final client = ref.watch(dataClientProvider);
  final prefs = ref.watch(sharedPrefsProvider);
  return BookmarksController(ref, client, prefs);
});
