import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_provider.dart';

const _bookmarkKey = 'bookmarked_ids';

class BookmarksController extends StateNotifier<Set<int>> {
  BookmarksController(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Set<int> _load(SharedPreferences prefs) {
    final stored = prefs.getStringList(_bookmarkKey) ?? const [];
    return stored
        .map((value) => int.tryParse(value))
        .whereType<int>()
        .toSet();
  }

  bool isBookmarked(int id) => state.contains(id);

  void toggle(int id) {
    final next = Set<int>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    _prefs.setStringList(
      _bookmarkKey,
      next.map((value) => value.toString()).toList(),
    );
  }

  void clear() {
    state = <int>{};
    _prefs.remove(_bookmarkKey);
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksController, Set<int>>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return BookmarksController(prefs);
});
