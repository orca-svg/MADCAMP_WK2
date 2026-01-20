import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
          final cookieName = _prefs.getString(_cookieNameKey) ??
              (dotenv.env['SESSION_COOKIE_NAME'] ?? 'session');
          final token = _prefs.getString(_sessionTokenKey);
          if (token != null && token.isNotEmpty) {
            // Dio는 Cookie 헤더에 "name=value" 형태로 전달하면 됩니다.
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

  // ✅ .env 기반 baseUrl 우선 -> 없으면 플랫폼별 기본값 fallback
  String _resolveBaseUrl() {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim();
    }

    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  // -------------------------
  // Auth
  // -------------------------

  /// ✅ 백엔드가 Set-Cookie로 세션을 내려주는 로그인
  /// 기대: POST /auth/login -> Set-Cookie: session=xxxx; Path=/; HttpOnly; ...
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      options: Options(
        // 로그인 응답에서 headers(Set-Cookie) 읽어야 하므로
        // 별도 옵션은 필요 없지만, 혹시 프록시/캐시 이슈 방지용
        followRedirects: false,
        validateStatus: (code) => code != null && code >= 200 && code < 500,
      ),
    );

    // 1) 성공 여부(프로젝트 백엔드 규격에 맞게 조정 가능)
    final ok = (res.statusCode ?? 0) >= 200 && (res.statusCode ?? 0) < 300;

    // 2) Set-Cookie 파싱해서 세션 저장
    // Dio는 'set-cookie'가 List<String>으로 들어옵니다.
    final setCookies = res.headers.map['set-cookie'] ?? const <String>[];
    final saved = await _trySaveSessionFromSetCookie(setCookies);

    // 3) 응답 바디(Map) 반환
    final data = (res.data is Map<String, dynamic>)
        ? (res.data as Map<String, dynamic>)
        : <String, dynamic>{};

    return {
      'success': ok,
      'sessionSaved': saved,
      'data': data,
      'statusCode': res.statusCode,
    };
  }

  Future<bool> _trySaveSessionFromSetCookie(List<String> setCookies) async {
    if (setCookies.isEmpty) return false;

    // 보통 "session=TOKEN; Path=/; HttpOnly; ..." 형태
    // 여러 쿠키가 올 수 있으니 첫 번째로 매칭되는 것 찾기
    final preferredName =
        dotenv.env['SESSION_COOKIE_NAME']?.trim().isNotEmpty == true
            ? dotenv.env['SESSION_COOKIE_NAME']!.trim()
            : 'session';

    // 1) 우선 preferredName으로 찾기
    String? pair = setCookies.firstWhere(
      (c) => c.startsWith('$preferredName='),
      orElse: () => '',
    );
    if (pair.isEmpty) {
      // 2) 못 찾으면 "something=value" 형태의 첫 쿠키 사용
      pair = setCookies.first;
    }

    final firstPart = pair.split(';').first.trim(); // name=value
    final eqIndex = firstPart.indexOf('=');
    if (eqIndex <= 0) return false;

    final name = firstPart.substring(0, eqIndex).trim();
    final value = firstPart.substring(eqIndex + 1).trim();
    if (name.isEmpty || value.isEmpty) return false;

    await saveSessionToken(value, cookieName: name);
    return true;
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
    // 쿠키 이름도 지우는 게 깔끔합니다.
    await _prefs.remove(_cookieNameKey);
  }

  Future<void> saveSessionToken(String token,
      {String cookieName = 'session'}) async {
    await _prefs.setString(_sessionTokenKey, token);
    await _prefs.setString(_cookieNameKey, cookieName);
  }

  String? readSessionToken() => _prefs.getString(_sessionTokenKey);
}
