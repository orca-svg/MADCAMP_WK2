import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataClient {
  DataClient({
    required SharedPreferences prefs,
    Dio? dio,
  })  : _prefs = prefs,
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = _resolveBaseUrl()
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15);

    // ✅ 모든 요청에 session 쿠키 자동 첨부
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final cookieName = _prefs.getString(_cookieNameKey) ?? 'session';
          final token = _prefs.getString(_sessionTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Cookie'] = '$cookieName=$token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static const _sessionTokenKey = 'session_token';
  static const _cookieNameKey = 'session_cookie_name';

  final SharedPreferences _prefs;
  final Dio _dio;

  Dio get dio => _dio;

  // ✅ 로컬 개발 기준 baseUrl 자동 추정
  // - iOS Simulator: localhost
  // - Android Emulator: 10.0.2.2
  String _resolveBaseUrl() {
    final env = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;

    if (kIsWeb) return 'http://localhost:3000';

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    return {'success': false};
  }

  Future<void> logout() async {
    // 서버에서 세션 삭제 시도(실패해도 로컬은 로그아웃)
    try {
      await _dio.get('/auth/logout');
    } catch (_) {}
    await _prefs.remove(_sessionTokenKey);
  }

  Future<void> saveSessionToken(String token, {String cookieName = 'session'}) async {
    await _prefs.setString(_sessionTokenKey, token);
    await _prefs.setString(_cookieNameKey, cookieName);
  }

  String? readSessionToken() => _prefs.getString(_sessionTokenKey);
}
