import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      if (mounted) _showSnack('로그인을 시작할 수 없어요.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final powerOn = ref.watch(powerStateProvider);
    final auth = ref.watch(authProvider);

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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('공명에 접속하기', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Google 계정으로 공명에 함께하기',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_isSubmitting || auth.isLoading) ? null : _startGoogleLogin,
                          child: (_isSubmitting || auth.isLoading)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.4),
                                )
                              : const Text('Google로 로그인'),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        '로그인 완료 후 자동으로 홈으로 이동합니다.',
                        style: theme.textTheme.bodySmall,
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
