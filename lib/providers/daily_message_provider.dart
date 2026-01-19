import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/comfort_repository.dart';
import 'prefs_provider.dart';

class DailyMessageState {
  final int? messageId;
  final String? message;
  final bool isRepeat;
  final bool hasTuned;
  final bool hasSeenTodayMessage;
  final String? lastSeenDate;
  final DateTime? firstCheckTime;

  const DailyMessageState({
    this.messageId,
    this.message,
    this.isRepeat = false,
    this.hasTuned = false,
    this.hasSeenTodayMessage = false,
    this.lastSeenDate,
    this.firstCheckTime,
  });

  DailyMessageState copyWith({
    int? messageId,
    String? message,
    bool? isRepeat,
    bool? hasTuned,
    bool? hasSeenTodayMessage,
    String? lastSeenDate,
    DateTime? firstCheckTime,
  }) {
    return DailyMessageState(
      messageId: messageId ?? this.messageId,
      message: message ?? this.message,
      isRepeat: isRepeat ?? this.isRepeat,
      hasTuned: hasTuned ?? this.hasTuned,
      hasSeenTodayMessage:
          hasSeenTodayMessage ?? this.hasSeenTodayMessage,
      lastSeenDate: lastSeenDate ?? this.lastSeenDate,
      firstCheckTime: firstCheckTime ?? this.firstCheckTime,
    );
  }
}

class DailyMessageController extends StateNotifier<DailyMessageState> {
  DailyMessageController(this._prefs) : super(const DailyMessageState());

  final SharedPreferences _prefs;
  final ComfortRepository _repository = ComfortRepository();

  void power() {
    final result = _repository.getDailyComfort(_prefs);

    state = DailyMessageState(
      messageId: result.id,
      message: result.message,
      isRepeat: result.isRepeat,
      hasTuned: true,
      hasSeenTodayMessage: true,
      lastSeenDate: result.dateKey,
      firstCheckTime: result.seenAt,
    );
  }

  void resetSession() {
    state = const DailyMessageState();
  }
}

final dailyMessageProvider =
    StateNotifierProvider<DailyMessageController, DailyMessageState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return DailyMessageController(prefs);
});
