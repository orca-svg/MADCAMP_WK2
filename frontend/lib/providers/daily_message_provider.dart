import 'package:flutter/foundation.dart';
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
const _messageSourceKey = 'daily_message_source';

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
    var storedDate = _prefs.getString(_messageDateKey);
    final rawId = _prefs.get(_messageIdKey);
    final storedId = rawId is String
        ? rawId
        : (rawId is int ? rawId.toString() : null);
    var storedMessage = _prefs.getString(_messageContentKey);
    var storedSeenAt = _prefs.getString(_messageSeenAtKey);
    final source = _prefs.getString(_messageSourceKey);

    final isLegacySource = source != 'api';
    final isLegacyId = storedId != null && !_looksLikeUuid(storedId);
    if (isLegacySource || isLegacyId) {
      await _prefs.remove(_messageDateKey);
      await _prefs.remove(_messageIdKey);
      await _prefs.remove(_messageContentKey);
      await _prefs.remove(_messageSeenAtKey);
      storedDate = null;
      storedMessage = null;
      storedSeenAt = null;
    }

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

    try {
      debugPrint('dailyMessage baseUrl=${_client.dio.options.baseUrl}');
      final res = await _client.dio.get('/advice/random');
      debugPrint('dailyMessage response=${res.data}');
      final resData = res.data;
      final obj = (resData is Map && resData['data'] is Map)
          ? extractObject(resData['data'])
          : extractObject(resData);
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
      _prefs.setString(_messageSourceKey, 'api');

      debugPrint('dailyMessage set id=$id message=$message');
      state = DailyMessageState(
        messageId: id,
        message: message,
        isRepeat: false,
        hasTuned: true,
        hasSeenTodayMessage: true,
        lastSeenDate: today,
        firstCheckTime: seenAt,
      );
    } catch (e) {
      debugPrint('dailyMessage error=$e');
      // Keep state unchanged on error.
    }
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

  bool _looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}

final dailyMessageProvider =
    StateNotifierProvider<DailyMessageController, DailyMessageState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  final client = ref.watch(dataClientProvider);
  return DailyMessageController(prefs, client);
});
