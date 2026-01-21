import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import 'auth_provider.dart';
import 'board_provider.dart';

class BookmarksController extends StateNotifier<Set<String>> {
  BookmarksController(this._ref, this._client) : super(<String>{}) {
    _bindAuth();
  }

  final Ref _ref;
  final DataClient _client;
  Dio get _dio => _client.dio;

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
      final res = await _dio.get('/bookmarks');
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

  Future<void> toggle(String adviceId) async {
    final next = Set<String>.from(state);
    final isRemoving = next.contains(adviceId);
    if (isRemoving) {
      next.remove(adviceId);
    } else {
      next.add(adviceId);
    }
    state = next;

    try {
      if (isRemoving) {
        await _dio.delete('/bookmarks', queryParameters: {'adviceId': adviceId});
      } else {
        await _dio.post('/bookmarks', data: {'adviceId': adviceId});
      }
    } catch (_) {
      await refresh();
    }
  }

  void clear() => state = <String>{};
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksController, Set<String>>((ref) {
  final client = ref.watch(dataClientProvider);
  return BookmarksController(ref, client);
});
