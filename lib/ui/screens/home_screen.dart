import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bookmarks_provider.dart';
import '../../providers/daily_message_provider.dart';
import '../../providers/power_provider.dart';
import '../widgets/radio_tone.dart';

const _readableBodyFont = 'ChosunCentennial';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageState = ref.watch(dailyMessageProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final powerOn = ref.watch(powerStateProvider);
    final theme = Theme.of(context);

    final messageId = messageState.messageId;
    final isBookmarked =
        messageId != null && bookmarks.contains(messageId);

    return IndexedStack(
      index: powerOn ? 1 : 0,
      children: [
        _PowerOffContent(
          key: const ValueKey('power_off'),
          theme: theme,
        ),
        _PowerOnContent(
          key: const ValueKey('power_on'),
          theme: theme,
          messageState: messageState,
          isBookmarked: isBookmarked,
          onToggleBookmark: messageId == null
              ? null
              : () => ref
                  .read(bookmarksProvider.notifier)
                  .toggle(messageId),
        ),
      ],
    );
  }
}

class _PowerOffContent extends StatelessWidget {
  const _PowerOffContent({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text(
          '라디오 전원이 꺼져 있어요.',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: RadioTone.textPrimary.withOpacity(0.92),
            height: 1.38,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '전원을 눌러 오늘의 위로를 수신해 보세요.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: RadioTone.textSecondary.withOpacity(0.82),
            height: 1.38,
          ),
        ),
      ],
    );
  }
}

class _PowerOnContent extends StatelessWidget {
  const _PowerOnContent({
    super.key,
    required this.theme,
    required this.messageState,
    required this.isBookmarked,
    required this.onToggleBookmark,
  });

  final ThemeData theme;
  final DailyMessageState messageState;
  final bool isBookmarked;
  final VoidCallback? onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text(
          '오늘의 위로 메시지',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: RadioTone.textPrimary.withOpacity(0.92),
            height: 1.38,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '전원을 눌러 오늘의 위로를 한 번만 받아보세요.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: RadioTone.textSecondary.withOpacity(0.82),
            height: 1.38,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          messageState.message ?? '',
          style: theme.textTheme.titleLarge?.copyWith(
            height: 1.38,
            color: RadioTone.textPrimary.withOpacity(0.92),
            fontFamily: _readableBodyFont,
          ),
        ),
        const SizedBox(height: 12),
        if (messageState.isRepeat)
          Text(
            '오늘 이미 받은 위로예요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: RadioTone.textSecondary.withOpacity(0.8),
            ),
          ),
        if (messageState.hasTuned) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _BookmarkButton(
                isActive: isBookmarked,
                onTap: onToggleBookmark,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BookmarkButton extends StatefulWidget {
  const _BookmarkButton({
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton> {
  bool _pressed = false;

  Future<void> _handleTap() async {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    setState(() => _pressed = true);
    widget.onTap?.call();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? const Color(0xFFE0B66B)
        : const Color(0xFFB79E7A).withOpacity(0.85);

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: widget.onTap == null ? null : _handleTap,
          radius: 28,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              widget.isActive ? Icons.bookmark : Icons.bookmark_border,
              size: 24,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
