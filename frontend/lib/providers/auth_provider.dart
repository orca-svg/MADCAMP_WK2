import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_client.dart'; // ✅ 변경
import 'prefs_provider.dart';

class AuthState {
  final bool isSignedIn;
  final bool isLoading;
  final Map<String, dynamic>? user;
  final String? sessionToken;

  const AuthState({
    required this.isSignedIn,
    required this.isLoading,
    required this.user,
    required this.sessionToken,
  });

  factory AuthState.signedOut() => const AuthState(
        isSignedIn: false,
        isLoading: false,
        user: null,
        sessionToken: null,
      );

  String get displayName {
    final u = user;
    if (u == null) return 'Guest';
    return (u['nickname'] ?? u['name'] ?? u['email'] ?? 'Guest').toString();
  }

  String get userIdLikeKey {
    final u = user;
    if (u == null) return '';
    return (u['id'] ?? u['email'] ?? '').toString();
  }

  AuthState copyWith({
    bool? isSignedIn,
    bool? isLoading,
    Map<String, dynamic>? user,
    String? sessionToken,
  }) {
    return AuthState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      sessionToken: sessionToken ?? this.sessionToken,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._prefs) : super(AuthState.signedOut()) {
    _client = DataClient(prefs: _prefs);
    _init();
  }

  final SharedPreferences _prefs;
  late final DataClient _client;

  StreamSubscription<Uri>? _sub;

  Future<void> _init() async {
    _listenDeepLinks();
    await refreshSession();
  }

  void _listenDeepLinks() {
    final appLinks = AppLinks();

    appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleAuthLink(uri);
    });

    _sub = appLinks.uriLinkStream.listen((uri) {
      _handleAuthLink(uri);
    });
  }

  Future<void> startGoogleLogin() async {
    final url = Uri.parse('${_client.dio.options.baseUrl}/auth/google');

    state = state.copyWith(isLoading: true);

    final ok = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!ok) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _handleAuthLink(Uri uri) async {
    // madcamp2://auth?sessionToken=...
    if (uri.scheme != 'madcamp2') return;
    if (uri.host != 'auth') return;

    final token = uri.queryParameters['sessionToken'];
    final loggedOut = uri.queryParameters['loggedOut'];

    if (loggedOut == 'true') {
      await signOut();
      return;
    }

    if (token == null || token.isEmpty) return;

    await _client.saveSessionToken(token);
    await refreshSession();
  }

  Future<void> refreshSession() async {
    final token = _client.readSessionToken();
    if (token == null || token.isEmpty) {
      state = AuthState.signedOut();
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final me = await _client.getMe();
      final success = me['success'] == true;

      if (!success) {
        // 토큰 제거
        await _prefs.remove('session_token');
        state = AuthState.signedOut();
        return;
      }

      final user = (me['user'] is Map<String, dynamic>)
          ? (me['user'] as Map<String, dynamic>)
          : null;

      state = AuthState(
        isSignedIn: true,
        isLoading: false,
        user: user,
        sessionToken: token,
      );
    } catch (_) {
      state = AuthState.signedOut();
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _client.logout();
    state = AuthState.signedOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return AuthController(prefs);
});
