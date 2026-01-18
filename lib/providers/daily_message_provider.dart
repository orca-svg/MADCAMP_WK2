import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/messages.dart';
import 'prefs_provider.dart';

const _messageIdKey = 'daily_message_id';
const _messageDateKey = 'daily_message_date';

class DailyMessageState {
  final int? messageId;
  final String? message;
  final bool isRepeat;
  final bool hasTuned;

  const DailyMessageState({
    this.messageId,
    this.message,
    this.isRepeat = false,
    this.hasTuned = false,
  });

  DailyMessageState copyWith({
    int? messageId,
    String? message,
    bool? isRepeat,
    bool? hasTuned,
  }) {
    return DailyMessageState(
      messageId: messageId ?? this.messageId,
      message: message ?? this.message,
      isRepeat: isRepeat ?? this.isRepeat,
      hasTuned: hasTuned ?? this.hasTuned,
    );
  }
}

class DailyMessageController extends StateNotifier<DailyMessageState> {
  DailyMessageController(this._prefs) : super(const DailyMessageState());

  final SharedPreferences _prefs;
  final Random _random = Random();

  void power() {
    final today = _todayStamp();
    final storedDate = _prefs.getString(_messageDateKey);
    final storedId = _prefs.getInt(_messageIdKey);

    int chosenId;
    bool isRepeat = false;

    if (storedDate == today && storedId != null && _isValidId(storedId)) {
      chosenId = storedId;
      isRepeat = true;
    } else {
      chosenId = _random.nextInt(kComfortMessages.length);
      _prefs.setString(_messageDateKey, today);
      _prefs.setInt(_messageIdKey, chosenId);
    }

    state = DailyMessageState(
      messageId: chosenId,
      message: kComfortMessages[chosenId],
      isRepeat: isRepeat,
      hasTuned: true,
    );
  }

  void resetSession() {
    state = const DailyMessageState();
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

final dailyMessageProvider =
    StateNotifierProvider<DailyMessageController, DailyMessageState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return DailyMessageController(prefs);
});
