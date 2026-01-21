import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_client.dart';
import '../data/api_models.dart';
import 'board_provider.dart';
import 'prefs_provider.dart';

const _messageIdKey = 'daily_message_id';
const _messageDateKey = 'daily_message_date';
const _messageSeenAtKey = 'daily_message_seen_at';
const _messageContentKey = 'daily_message_content';

class DailyMessageState {
  final String? messageId;
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
    String? messageId,
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
  DailyMessageController(this._prefs, this._client)
      : super(const DailyMessageState());

  final SharedPreferences _prefs;
  final DataClient _client;

  Future<void> power() async {
    final today = _todayStamp();
    final storedDate = _prefs.getString(_messageDateKey);
    final storedId = _prefs.getString(_messageIdKey);
    final storedMessage = _prefs.getString(_messageContentKey);
    final storedSeenAt = _prefs.getString(_messageSeenAtKey);

    if (storedDate == today && storedId != null && storedMessage != null) {
      final seenAt = storedSeenAt != null
          ? DateTime.tryParse(storedSeenAt) ?? DateTime.now()
          : DateTime.now();
      state = DailyMessageState(
        messageId: storedId,
        message: storedMessage,
        isRepeat: true,
        hasTuned: true,
        hasSeenTodayMessage: true,
        lastSeenDate: storedDate,
        firstCheckTime: seenAt,
      );
      return;
    }

    final res = await _client.dio.get('/advice/random');
    final obj = extractObject(res.data);
    final id = obj['id']?.toString();
    final message = (obj['content'] ?? '').toString();
    if (id == null || id.isEmpty || message.isEmpty) {
      return;
    }

    final seenAt = DateTime.now();
    _prefs.setString(_messageDateKey, today);
    _prefs.setString(_messageIdKey, id);
    _prefs.setString(_messageContentKey, message);
    _prefs.setString(_messageSeenAtKey, seenAt.toIso8601String());

    state = DailyMessageState(
      messageId: id,
      message: message,
      isRepeat: false,
      hasTuned: true,
      hasSeenTodayMessage: true,
      lastSeenDate: today,
      firstCheckTime: seenAt,
    );
  }

  void resetSession() {
    state = const DailyMessageState();
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
  final client = ref.watch(dataClientProvider);
  return DailyMessageController(prefs, client);
});
