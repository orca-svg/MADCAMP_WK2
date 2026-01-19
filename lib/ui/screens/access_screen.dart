import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/power_provider.dart';

enum AccessMode { login, signup }

class AccessScreen extends ConsumerStatefulWidget {
  const AccessScreen({super.key, required this.mode});

  final AccessMode mode;

  @override
  ConsumerState<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends ConsumerState<AccessScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _nicknameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _agreed = false;
  bool _isSubmitting = false;

  static const _blockedUsernames = ['radio_test', 'admin', 'test'];
  static const _blockedNicknames = ['alice', 'radio'];

  @override
  void dispose() {
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _nicknameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFF3E7D3)),
        ),
        backgroundColor: const Color(0xFF2B2620),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSubmitting = true);
    final error = await ref.read(authProvider.notifier).login(
          username: _loginUsernameController.text.trim(),
          password: _loginPasswordController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (error != null) {
      _showSnack(error);
      return;
    }
  }

  Future<void> _submitSignup() async {
    final isValid = _signupFormKey.currentState?.validate() ?? false;
    if (!isValid || !_agreed) {
      _showSnack('필수 항목을 모두 입력해 주세요.');
      return;
    }
    final nickname = _nicknameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (_blockedNicknames.contains(nickname.toLowerCase())) {
      _showSnack('이미 사용 중인 닉네임입니다.');
      return;
    }
    if (_blockedUsernames.contains(username.toLowerCase())) {
      _showSnack('이미 사용 중인 아이디입니다.');
      return;
    }
    if (password.length < 6) {
      _showSnack('비밀번호는 6자 이상이어야 합니다.');
      return;
    }
    if (password != confirm) {
      _showSnack('비밀번호 확인이 일치하지 않습니다.');
      return;
    }

    setState(() => _isSubmitting = true);
    final error = await ref.read(authProvider.notifier).signUp(
          nickname: nickname,
          username: username,
          password: password,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (error != null) {
      _showSnack(error);
    }
  }

  void _setMode(AccessMode mode) {
    final next =
        mode == AccessMode.signup ? '/access?mode=signup' : '/access';
    context.go(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final powerOn = ref.watch(powerStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset + 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offsetTween = Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: animation.drive(offsetTween),
                        child: child,
                      ),
                    );
                  },
                  child: widget.mode == AccessMode.login
                      ? _AccessCard(
                          key: const ValueKey('login'),
                          powerOn: powerOn,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '다시 만나서 반가워요',
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '아이디와 비밀번호로 로그인하세요.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 14),
                              Form(
                                key: _loginFormKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _loginUsernameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: '아이디',
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return '아이디를 입력해 주세요.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _loginPasswordController,
                                      textInputAction: TextInputAction.done,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: '비밀번호',
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return '비밀번호를 입력해 주세요.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      height: 52,
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isSubmitting ? null : _submitLogin,
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Color(0xFF1B1410),
                                                  ),
                                                ),
                                              )
                                            : const Text('Login'),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => _setMode(AccessMode.signup),
                                      child: const Text('회원가입'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : _AccessCard(
                          key: const ValueKey('signup'),
                          powerOn: powerOn,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '당신의 라디오를 만들어 보세요',
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '닉네임과 계정을 설정해 주세요.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 14),
                              Form(
                                key: _signupFormKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _nicknameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: '닉네임',
                                      ),
                                      validator: (value) {
                                        final trimmed = value?.trim() ?? '';
                                        if (trimmed.isEmpty) {
                                          return '닉네임을 입력해 주세요.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _usernameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: '아이디',
                                      ),
                                      validator: (value) {
                                        final trimmed = value?.trim() ?? '';
                                        if (trimmed.isEmpty) {
                                          return '아이디를 입력해 주세요.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _passwordController,
                                      textInputAction: TextInputAction.next,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: '비밀번호',
                                      ),
                                      validator: (value) {
                                        final trimmed = value?.trim() ?? '';
                                        if (trimmed.isEmpty) {
                                          return '비밀번호를 입력해 주세요.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _confirmController,
                                      textInputAction: TextInputAction.done,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: '비밀번호 확인',
                                      ),
                                      validator: (value) {
                                        final trimmed = value?.trim() ?? '';
                                        if (trimmed.isEmpty) {
                                          return '비밀번호 확인을 입력해 주세요.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: _agreed,
                                      onChanged: (value) {
                                        setState(
                                          () => _agreed = value ?? false,
                                        );
                                      },
                                      title: const Text(
                                        '오늘의 위로를 수신하는 것에 동의합니다.',
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 52,
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : _submitSignup,
                                        child: Text(
                                          _isSubmitting
                                              ? '가입 중...'
                                              : 'Sign Up',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => _setMode(AccessMode.login),
                                      child: const Text('로그인으로 돌아가기'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    super.key,
    required this.child,
    required this.powerOn,
  });

  final Widget child;
  final bool powerOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: powerOn ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
        boxShadow: [
          BoxShadow(
            color: powerOn ? const Color(0x66F5D27A) : const Color(0x44000000),
            blurRadius: powerOn ? 18 : 10,
            spreadRadius: powerOn ? 2 : 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
