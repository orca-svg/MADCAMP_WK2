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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '라디오 전원이 꺼져 있어요.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: RadioTone.textPrimary.withOpacity(0.92),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '전원을 눌러 오늘의 위로를 수신해 보세요.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
                color: RadioTone.textSecondary.withOpacity(0.82),
              ),
            ),
          ],
        ),
      ),
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
    final dateStamp = messageState.lastSeenDate;
    final showBadge = messageState.hasSeenTodayMessage && dateStamp != null;
    final formattedDate =
        dateStamp == null ? '' : _formatDateDisplay(dateStamp);
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
        if (showBadge) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: _DateBadge(
              dateText: formattedDate,
              showSeen: messageState.isRepeat,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          messageState.message ?? '',
          style: theme.textTheme.titleLarge?.copyWith(
            height: 1.38,
            color: RadioTone.textPrimary.withOpacity(0.92),
            fontFamily: _readableBodyFont,
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

class _DateBadge extends StatelessWidget {
  const _DateBadge({
    required this.dateText,
    required this.showSeen,
  });

  final String dateText;
  final bool showSeen;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x33171411),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xEBF2EBDD),
            ),
          ),
          if (showSeen) ...[
            const SizedBox(width: 8),
            const Text(
              '이미 확인한 문구에요.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xD9D7CCB9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDateDisplay(String date) {
  final parts = date.split('-');
  if (parts.length != 3) return date;
  return '${parts[0]}.${parts[1]}.${parts[2]}';
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
          containedInkWell: true,
          customBorder: const CircleBorder(),
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
