import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/board_provider.dart';
import '../../providers/comments_provider.dart';
import '../../providers/daily_message_provider.dart';
import '../../providers/power_provider.dart';

// ✅ speaker 텍스처 (프로젝트 경로: frontend/assets/textures/fabric_grille.png)
const String _speakerTexturePath = 'assets/textures/fabric_grille.png';

// ✅ speaker 톤에 맞춘 불투명 패널 베이스
const Color _speakerBase = Color(0xFF171411);
const Color _divider = Color(0x22D7CCB9);

BoxDecoration _speakerTextureDecoration({Alignment alignment = Alignment.center}) {
  return BoxDecoration(
    color: _speakerBase, // ✅ 기본이 불투명(wood 비침 방지)
    image: DecorationImage(
      image: const AssetImage(_speakerTexturePath),
      fit: BoxFit.cover,
      alignment: alignment,
      // ✅ 텍스처 위에 어두운 필터를 얹어 "speaker와 동일한 깊이" 유지
      colorFilter: ColorFilter.mode(
        const Color(0xFF0B0908).withValues(alpha: 0.35),
        BlendMode.darken,
      ),
    ),
  );
}

class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  bool _loggingOut = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final myPosts = ref.watch(myPostsProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final adoptedAsync = ref.watch(myAdoptedCommentsProvider);
    final theme = Theme.of(context);

    final nickname = authState.displayName;
    final myPostsCount = myPosts.length;
    final acceptedCount = adoptedAsync.maybeWhen(
      data: (comments) => comments.length,
      orElse: () => 0,
    );
    final bookmarkCount = bookmarks.length;

    return CustomScrollView(
      slivers: [
        // ✅ 상단바: wood 비침 제거 + speaker 텍스처로 불투명 상단바 구현
        SliverPersistentHeader(
          pinned: true,
          delegate: _MyHeaderDelegate(
            title: 'MY RADIO',
            onLogout: _loggingOut
                ? null
                : () async {
                    setState(() => _loggingOut = true);
                    ref.read(powerStateProvider.notifier).setPower(false);
                    await ref.read(authProvider.notifier).signOut();
                    ref.read(dailyMessageProvider.notifier).resetSession();
                    if (!mounted) return;
                    context.pushReplacement('/access');
                    await Future<void>.delayed(const Duration(milliseconds: 800));
                    if (!mounted) return;
                    setState(() => _loggingOut = false);
                  },
          ),
        ),

        // ✅ 헤더 아래 영역도 "동일한 speaker 톤"으로 (갈색 wood 비침 방지)
        SliverToBoxAdapter(
          child: Container(
            decoration: _speakerTextureDecoration(alignment: Alignment.topCenter),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$nickname님이 라디오에 함께하고 있어요.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFD7CCB9).withValues(alpha: 0.86),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: Row(
                      children: [
                        Expanded(
                          child: _CountButton(
                            label: '내 사연',
                            count: myPostsCount,
                            onTap: () => context.push('/my/posts'),
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
                            onTap: () => debugPrint('TODO: open bookmarked comforts list'),
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
                      color: const Color(0xFFD7CCB9).withValues(alpha: 0.85),
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
        ),

        SliverToBoxAdapter(
          child: Container(
            decoration: _speakerTextureDecoration(),
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
                              commentCount: 0,
                              empathyCount: post.empathyCount,
                              isAccepted: post.acceptedCommentId != null,
                              onTap: () => context.go('/my/detail/${post.id}'),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _MyHeaderDelegate({
    required this.title,
    required this.onLogout,
  });

  final String title;
  final VoidCallback? onLogout;

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);

    return Container(
      height: 52,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      // ✅ 기존: 반투명 단색(color) → speaker 텍스처 + 불투명 베이스
      decoration: _speakerTextureDecoration(alignment: Alignment.topCenter),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -5),
                child: _LogoutButton(onTap: onLogout),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 1, color: _divider),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MyHeaderDelegate oldDelegate) {
    return oldDelegate.title != title || oldDelegate.onLogout != onLogout;
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0x22FF4D4D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x66FF4D4D), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  '로그아웃',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xEBFF4D4D),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    return SizedBox(
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0x24171411),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD7CCB9),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    count.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF2EBDD),
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

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = score / 100.0;
    return Row(
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final intensity = value.clamp(0.0, 1.0);
              final fillBase = Color.lerp(
                const Color(0x88D7CCB9),
                const Color(0xFFD7CCB9),
                intensity,
              )!;
              final fillHighlight = Color.lerp(
                const Color(0x88F2EBDD),
                const Color(0xFFF2EBDD),
                intensity,
              )!;
              return Container(
                height: 12,
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
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [fillBase, fillHighlight],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$score / 100',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFD7CCB9).withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

int _calculateScore({
  required int storiesCount,
  required int acceptedCount,
  required int bookmarkCount,
}) {
  final raw = storiesCount * 3 + acceptedCount * 7 + bookmarkCount;
  return raw > 100 ? 100 : raw;
}

class _MyPostCard extends StatelessWidget {
  const _MyPostCard({
    required this.title,
    required this.tags,
    required this.createdAt,
    required this.commentCount,
    required this.empathyCount,
    required this.isAccepted,
    required this.onTap,
  });

  final String title;
  final List<String> tags;
  final DateTime createdAt;
  final int commentCount;
  final int empathyCount;
  final bool isAccepted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acceptColor = isAccepted
        ? const Color(0xFFF2EBDD).withValues(alpha: 0.95)
        : const Color(0xFFD7CCB9).withValues(alpha: 0.55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0x24171411),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1FD7CCB9), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        color: const Color(0xFFF2EBDD).withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  Icon(
                    isAccepted ? Icons.verified : Icons.verified_outlined,
                    size: 18,
                    color: acceptColor,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (tags.isNotEmpty) ...[
                _MyTagRow(tags: tags),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Text(
                    _formatDate(createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD7CCB9).withValues(alpha: 0.70),
                    ),
                  ),
                  const Spacer(),
                  _StatIconText(
                    icon: Icons.chat_bubble_outline,
                    value: commentCount.toString(),
                  ),
                  const SizedBox(width: 10),
                  _StatIconText(
                    icon: Icons.favorite_border,
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

  String _formatDate(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}

class _MyTagRow extends StatelessWidget {
  const _MyTagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < tags.length; i++) ...[
            _MyTagChip(label: tags[i]),
            if (i != tags.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _MyTagChip extends StatelessWidget {
  const _MyTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0x24171411),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xEBD7CCB9),
          ),
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
          color: const Color(0xFFD7CCB9).withValues(alpha: 0.72),
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
