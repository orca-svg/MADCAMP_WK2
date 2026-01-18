import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_provider.dart';

const _usernameKey = 'auth_username';
const _passwordKey = 'auth_password';
const _nicknameKey = 'auth_nickname';
const _signedInKey = 'auth_signed_in';
const _defaultUsername = 'radio_test';
const _defaultPassword = 'radio1234';
const _defaultNickname = 'Guest Listener';

Future<void> seedDefaultAccount(SharedPreferences prefs) async {
  final storedUsername = prefs.getString(_usernameKey);
  final storedPassword = prefs.getString(_passwordKey);
  final hasAccount = storedUsername != null &&
      storedUsername.isNotEmpty &&
      storedPassword != null &&
      storedPassword.isNotEmpty;
  if (hasAccount) return;

  await prefs.setString(_nicknameKey, _defaultNickname);
  await prefs.setString(_usernameKey, _defaultUsername);
  await prefs.setString(_passwordKey, _defaultPassword);
  await prefs.setBool(_signedInKey, false);
}

class AuthState {
  final bool isSignedIn;
  final String? username;
  final String? nickname;
  final bool hasAccount;

  const AuthState({
    required this.isSignedIn,
    required this.username,
    required this.nickname,
    required this.hasAccount,
  });

  AuthState copyWith({
    bool? isSignedIn,
    String? username,
    String? nickname,
    bool? hasAccount,
  }) {
    return AuthState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      hasAccount: hasAccount ?? this.hasAccount,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._prefs) : super(_load(_prefs)) {
    _ensureTestAccount();
  }

  final SharedPreferences _prefs;

  static AuthState _load(SharedPreferences prefs) {
    final username = prefs.getString(_usernameKey);
    final nickname = prefs.getString(_nicknameKey);
    final signedIn = prefs.getBool(_signedInKey) ?? false;
    final hasAccount = username != null && username.isNotEmpty;
    return AuthState(
      isSignedIn: signedIn && hasAccount,
      username: username,
      nickname: nickname,
      hasAccount: hasAccount,
    );
  }

  Future<String?> login({
    required String username,
    required String password,
  }) async {
    debugPrint('Auth login pressed: username=$username');
    final storedUsername = _prefs.getString(_usernameKey);
    final storedPassword = _prefs.getString(_passwordKey);

    if (storedUsername == null || storedPassword == null) {
      debugPrint('No stored account, using mock login fallback.');
      await _prefs.setString(_nicknameKey, username);
      await _prefs.setString(_usernameKey, username);
      await _prefs.setString(_passwordKey, password);
      await _prefs.setBool(_signedInKey, true);
      state = state.copyWith(
        isSignedIn: true,
        username: username,
        nickname: username,
        hasAccount: true,
      );
      return null;
    }
    if (storedUsername != username || storedPassword != password) {
      debugPrint('Login failed: invalid credentials.');
      return 'Username or password is incorrect.';
    }

    debugPrint('Login success.');
    await _prefs.setBool(_signedInKey, true);
    state = state.copyWith(
      isSignedIn: true,
      username: storedUsername,
      nickname: _prefs.getString(_nicknameKey),
      hasAccount: true,
    );
    return null;
  }

  Future<String?> signUp({
    required String nickname,
    required String username,
    required String password,
  }) async {
    if (username.isEmpty || password.isEmpty || nickname.isEmpty) {
      return 'All fields are required.';
    }

    await _prefs.setString(_nicknameKey, nickname);
    await _prefs.setString(_usernameKey, username);
    await _prefs.setString(_passwordKey, password);
    await _prefs.setBool(_signedInKey, true);

    state = AuthState(
      isSignedIn: true,
      username: username,
      nickname: nickname,
      hasAccount: true,
    );
    return null;
  }

  Future<void> signOut() async {
    await _prefs.setBool(_signedInKey, false);
    state = state.copyWith(isSignedIn: false);
  }

  Future<void> _ensureTestAccount() async {
    await seedDefaultAccount(_prefs);

    state = state.copyWith(
      isSignedIn: false,
      username: _prefs.getString(_usernameKey) ?? _defaultUsername,
      nickname: _prefs.getString(_nicknameKey) ?? _defaultNickname,
      hasAccount: true,
    );
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return AuthController(prefs);
});
