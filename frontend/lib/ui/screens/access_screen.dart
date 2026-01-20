import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';


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
  bool _isSubmitting = false;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Color(0xFFF3E7D3))),
        backgroundColor: const Color(0xFF2B2620),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _startGoogleLogin() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authProvider.notifier).startGoogleLogin();
      // 딥링크로 돌아오면 authProvider가 자동으로 isSignedIn 갱신
    } catch (_) {
      if (mounted) _showSnack('Google 로그인을 시작할 수 없어요.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // 일반 Sign in 버튼(원하시면 추후 이메일/아이디 로그인으로 연결)
  Future<void> _signIn() async {
    _showSnack('현재는 Google 로그인만 지원합니다.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final powerOn = ref.watch(powerStateProvider);
    final auth = ref.watch(authProvider);

    final busy = _isSubmitting || auth.isLoading;

    final title = widget.mode == AccessMode.signup ? '시작하기' : '로그인';
    final subtitle = widget.mode == AccessMode.signup
        ? 'Google 계정으로 시작하면 계정이 자동으로 생성됩니다.'
        : 'Google 계정으로 로그인 후 앱으로 돌아옵니다.';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(16),
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
                    border: Border.all(
                      color: powerOn ? const Color(0x33FFFFFF) : const Color(0x22000000),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(subtitle, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 18),

                      // ✅ 통상적인 Google Sign-in 버튼
                      GoogleSignInButton(
                        enabled: !busy,
                        isLoading: busy,
                        onPressed: _startGoogleLogin,
                      ),

                      const SizedBox(height: 14),

                      // ✅ 일반 Sign in 버튼(Primary)
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: busy ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.4),
                                )
                              : const Text('Sign in'),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        '로그인 완료 후 자동으로 홈으로 이동합니다.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
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

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
    this.text = 'Google로 계속하기',
  });

  final VoidCallback onPressed;
  final bool enabled;
  final bool isLoading;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Material(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: (!enabled || isLoading) ? null : onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFF747775),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    Image.asset(
                      'assets/images/google_g.png',
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Opacity(
                    opacity: enabled ? 1.0 : 0.5,
                    child: Text(
                      isLoading ? '로그인 중...' : text,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 20 / 14,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGMark extends StatelessWidget {
  const _GoogleGMark();

  @override
  Widget build(BuildContext context) {
    return 
      Image.asset('assets/images/google_g.png', width: 18, height: 18);
  }
}
