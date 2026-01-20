import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prefs_provider.dart';

const _bookmarkKey = 'bookmarked_post_ids';

class BookmarksController extends StateNotifier<Set<String>> {
  BookmarksController(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Set<String> _load(SharedPreferences prefs) {
    final stored = prefs.getStringList(_bookmarkKey) ?? const [];
    return stored.where((e) => e.trim().isNotEmpty).toSet();
  }

  bool isBookmarked(String postId) => state.contains(postId);

  void toggle(String postId) {
    final next = Set<String>.from(state);
    if (next.contains(postId)) {
      next.remove(postId);
    } else {
      next.add(postId);
    }
    state = next;
    _prefs.setStringList(_bookmarkKey, next.toList());
  }

  void clear() {
    state = <String>{};
    _prefs.remove(_bookmarkKey);
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksController, Set<String>>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return BookmarksController(prefs);
});
