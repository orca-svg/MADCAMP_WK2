import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'messages.dart';

const _messageIdKey = 'daily_message_id';
const _messageDateKey = 'daily_message_date';
const _messageSeenAtKey = 'daily_message_seen_at';
const _messageRecentKey = 'daily_message_recent_ids';

class DailyComfort {
  const DailyComfort({
    required this.id,
    required this.message,
    required this.isRepeat,
    required this.dateKey,
    required this.seenAt,
  });

  final int id;
  final String message;
  final bool isRepeat;
  final String dateKey;
  final DateTime seenAt;
}

class ComfortRepository {
  ComfortRepository({Random? random}) : _random = random ?? Random();

  final Random _random;

  DailyComfort getDailyComfort(SharedPreferences prefs) {
    final today = _todayStamp();
    final storedDate = prefs.getString(_messageDateKey);
    final storedId = prefs.getInt(_messageIdKey);
    final storedSeenAt = prefs.getString(_messageSeenAtKey);
    if (storedDate == today && storedId != null && _isValidId(storedId)) {
      final seenAt = storedSeenAt != null
          ? DateTime.tryParse(storedSeenAt) ?? DateTime.now()
          : DateTime.now();
      return DailyComfort(
        id: storedId,
        message: kComfortMessages[storedId],
        isRepeat: true,
        dateKey: today,
        seenAt: seenAt,
      );
    }

    final recentIds = _readRecentIds(prefs);
    final chosenId = _pickNewId(recentIds);
    final seenAt = DateTime.now();
    prefs.setString(_messageDateKey, today);
    prefs.setInt(_messageIdKey, chosenId);
    prefs.setString(_messageSeenAtKey, seenAt.toIso8601String());
    _writeRecentIds(prefs, [chosenId, ...recentIds]);
    return DailyComfort(
      id: chosenId,
      message: kComfortMessages[chosenId],
      isRepeat: false,
      dateKey: today,
      seenAt: seenAt,
    );
  }

  int _pickNewId(List<int> recentIds) {
    if (kComfortMessages.isEmpty) return 0;
    int tries = 0;
    int chosen = _random.nextInt(kComfortMessages.length);
    while (tries < 8 && recentIds.contains(chosen)) {
      chosen = _random.nextInt(kComfortMessages.length);
      tries++;
    }
    return chosen;
  }

  List<int> _readRecentIds(SharedPreferences prefs) {
    final raw = prefs.getString(_messageRecentKey);
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
        .map((value) => int.tryParse(value))
        .whereType<int>()
        .where(_isValidId)
        .toList();
  }

  void _writeRecentIds(SharedPreferences prefs, List<int> ids) {
    final trimmed = ids.take(5).toList();
    prefs.setString(_messageRecentKey, trimmed.join(','));
  }

  bool _isValidId(int id) {
    return id >= 0 && id < kComfortMessages.length;
  }

  String _todayStamp() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
