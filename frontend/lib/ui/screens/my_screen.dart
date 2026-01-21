import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/board_provider.dart';
import '../../providers/daily_message_provider.dart';
import '../../providers/power_provider.dart';

class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  bool _loggingOut = false;

  // ✅ 로그인 완료 시 1회만 내 글 로드
  bool _didLoadMine = false;

  // ✅ 세션/상태 반영 타이밍 이슈 대비 1회 재시도
  bool _didRetryMine = false;

  ProviderSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    // ✅ build가 아니라 initState에서 listen (이벤트 누락 방지)
    _authSub = ref.listenManual<AuthState>(
      authProvider,
      (prev, next) async {
        if (!next.isSignedIn) {
          _didLoadMine = false;
          _didRetryMine = false;
          debugPrint('[MyScreen] signedOut -> reset flags');
          return;
        }

        if (_didLoadMine) return;
        if (next.isSignedIn && !next.isLoading) {
          _didLoadMine = true;
          await _refreshMineSafely(reason: 'auth_listener');
        }
      },
    );

    // ✅ 화면 진입 시 이미 로그인 완료인 케이스 커버
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final a = ref.read(authProvider);
      debugPrint(
        '[MyScreen] entry: signedIn=${a.isSignedIn} loading=${a.isLoading} name=${a.displayName}',
      );

      if (!mounted) return;
      if (a.isSignedIn && !a.isLoading && !_didLoadMine) {
        _didLoadMine = true;
        await _refreshMineSafely(reason: 'entry_postFrame');
      }
    });
  }

  @override
  void dispose() {
    _authSub?.close();
    super.dispose();
  }

  /// ✅ Google Auth 기반 표시명: name 우선 → nickname → email(@앞) → displayName
  String _nicknameFromAuth(AuthState state) {
    final u = state.user;
    if (u == null) return state.displayName;

    final name = (u['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;

    final nick = (u['nickname'] ?? '').toString().trim();
    if (nick.isNotEmpty) return nick;

    final email = (u['email'] ?? '').toString().trim();
    if (email.isNotEmpty) {
      final at = email.indexOf('@');
      if (at > 0) return email.substring(0, at);
      return email;
    }

    return state.displayName;
  }

  Future<void> _refreshMineSafely({required String reason}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    debugPrint('[MyScreen] refreshMine() start ($reason)');
    await ref.read(boardControllerProvider.notifier).refreshMine();

    // ✅ provider 캐시/파생 대비: UI 재계산 강제
    ref.invalidate(myPostsProvider);

    final afterFirst = ref.read(myPostsProvider);
    debugPrint('[MyScreen] refreshMine() done ($reason) -> myPosts=${afterFirst.length}');

    // ✅ 결과가 0이면 1회만 재시도
    if (afterFirst.isEmpty && !_didRetryMine) {
      _didRetryMine = true;
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      debugPrint('[MyScreen] refreshMine() retry');
      await ref.read(boardControllerProvider.notifier).refreshMine();
      ref.invalidate(myPostsProvider);

      final afterRetry = ref.read(myPostsProvider);
      debugPrint('[MyScreen] refreshMine() retry done -> myPosts=${afterRetry.length}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final myPosts = ref.watch(myPostsProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final theme = Theme.of(context);

    final nickname = _nicknameFromAuth(authState);

    final myPostsCount = myPosts.length;
    final acceptedCount = myPosts.where((p) => p.acceptedCommentId != null).length;
    final bookmarkCount = bookmarks.length;

    debugPrint('[MyScreen] build: myPosts=${myPosts.length}');

    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('[MyScreen] manual refreshMine()');
        await _refreshMineSafely(reason: 'manual_pull');
      },
      child: CustomScrollView(
        slivers: [
          // ✅ 오버플로우 해결: 헤더 높이를 충분히 확보 + 내부는 하나의 rounded 배경
          SliverPersistentHeader(
            pinned: true,
            delegate: _MyHeaderDelegate(
              nickname: nickname,
              onLogout: authState.isSignedIn
                  ? () async {
                      if (_loggingOut) return;
                      setState(() => _loggingOut = true);

                      await ref.read(authProvider.notifier).signOut();

                      // ✅ 프로젝트에 turnOff()가 없으므로 안전 리셋
                      ref.invalidate(powerStateProvider);

                      ref.read(dailyMessageProvider.notifier).resetSession();

                      _didLoadMine = false;
                      _didRetryMine = false;

                      if (!mounted) return;
                      context.pushReplacement('/access');

                      await Future<void>.delayed(const Duration(milliseconds: 800));
                      if (!mounted) return;
                      setState(() => _loggingOut = false);
                    }
                  : null,
            ),
          ),

          // ✅ 닉네임 텍스트는 헤더로 이동했으므로 아래에서는 제거
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 54,
                    child: Row(
                      children: [
                        Expanded(
                          child: _CountBadge(
                            label: '내 사연',
                            count: myPostsCount,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CountButton(
                            label: '채택된 위로',
                            count: acceptedCount,
                            onTap: () => context.push('/my/comforts'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CountButton(
                            label: '북마크',
                            count: bookmarkCount,
                            onTap: () => context.push('/my/bookmarks'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '주파수 세기',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFD7CCB9).withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ScoreGauge(
                    score: _calculateScore(
                      storiesCount: myPostsCount,
                      acceptedCount: acceptedCount,
                      bookmarkCount: bookmarkCount,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('내가 쓴 사연', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: myPosts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          '표시할 사연이 없어요.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (final post in myPosts)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                            child: _MyPostCard(
                              title: post.title,
                              tags: post.tags,
                              createdAt: post.createdAt,
                              empathyCount: post.empathyCount,
                              isAccepted: post.acceptedCommentId != null,
                              // ✅ 요구사항: 글 누르면 OpenDetailScreen으로 이동
                              onTap: () => context.push('/open/${post.id}'),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ 헤더는 "하나의 둥근 배경" 안에
/// - MY RADIO (headlineMedium)
/// - 로그아웃(옅은 빨강 배경)
/// - 닉네임 포함 문구
/// 그리고 구분선 제거
class _MyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _MyHeaderDelegate({
    required this.nickname,
    required this.onLogout,
  });

  final String nickname;
  final Future<void> Function()? onLogout;

  // ✅ 높이는 넉넉히 주되, 실제 제약이 더 작아도 Stack+Clip으로 overflow 방지
  static const double _h = 92;

  @override
  double get minExtent => _h;

  @override
  double get maxExtent => _h;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);

    // headlineMedium이 기기/테마에 따라 커질 수 있으니 height를 낮춰 안정화
    final titleStyle =
        (theme.textTheme.headlineMedium ?? theme.textTheme.titleLarge)?.copyWith(
      fontWeight: FontWeight.w900,
      color: const Color(0xFFF2EBDD),
      height: 0.95,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xE61F1A17),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x22D7CCB9), width: 1),
          ),
          // ✅ Column 대신 Stack: 상단 Row + 하단 텍스트로 고정 배치
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // 상단 Row
              Positioned(
                left: 14,
                right: 14,
                top: 10,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'MY RADIO',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (onLogout != null)
                      InkWell(
                        onTap: () => onLogout?.call(),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            // ✅ 옅은 빨강 배경
                            color: const Color(0x33FF3B30),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0x55FF3B30),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            '로그아웃',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFD2CE),
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 하단 닉네임 텍스트
              Positioned(
                left: 14,
                right: 14,
                bottom: 10,
                child: Text(
                  '$nickname님이 라디오에 함께하고 있어요.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    color: const Color(0xFFD7CCB9).withOpacity(0.86),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MyHeaderDelegate oldDelegate) {
    return oldDelegate.nickname != nickname || oldDelegate.onLogout != onLogout;
  }
}

int _calculateScore({
  required int storiesCount,
  required int acceptedCount,
  required int bookmarkCount,
}) {
  final s = (storiesCount * 12) + (acceptedCount * 25) + (bookmarkCount * 8);
  return s.clamp(0, 100);
}

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // ✅ 버튼 구분감: border
    return Material(
      color: const Color(0x14171411),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD7CCB9),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    count.toString(),
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF2EBDD),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Non-interactive count badge (display-only, no tap action)
class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x14171411),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD7CCB9),
                ),
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                count.toString(),
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF2EBDD),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (score / 100).clamp(0.0, 1.0);

    // ✅ 점수↑일수록 색 자체가 진해지도록
    final fillColor = Color.lerp(
      const Color(0xFFB9AC98),
      const Color(0xFF6E4F37),
      percent,
    )!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 14,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0x24171411),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '내 활동을 기반으로 계산된 주파수 강도예요.',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFD7CCB9).withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}

class _MyPostCard extends StatelessWidget {
  const _MyPostCard({
    required this.title,
    required this.tags,
    required this.createdAt,
    required this.empathyCount,
    required this.isAccepted,
    required this.onTap,
  });

  final String title;
  final List<String> tags;
  final DateTime createdAt;
  final int empathyCount;
  final bool isAccepted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ 미채택/채택: 텍스트 대신 아이콘(빈/채움)
    final icon = isAccepted ? Icons.check_circle : Icons.check_circle_outline;
    final iconColor = isAccepted
        ? const Color(0xFFF2EBDD).withOpacity(0.95)
        : const Color(0xFFD7CCB9).withOpacity(0.55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0x14171411),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFF2EBDD).withOpacity(0.92),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 18, color: iconColor),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final t in tags) _TagChip(text: t)],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    _formatDate(createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD7CCB9).withOpacity(0.70),
                    ),
                  ),
                  const Spacer(),
                  _StatIconText(
                    icon: Icons.favorite_rounded,
                    value: empathyCount.toString(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y.$m.$d';
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x24171411),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFFD7CCB9),
        ),
      ),
    );
  }
}

class _StatIconText extends StatelessWidget {
  const _StatIconText({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFFD7CCB9).withOpacity(0.72),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xBFD7CCB9),
          ),
        ),
      ],
    );
  }
}
