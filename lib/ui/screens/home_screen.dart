import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bookmarks_provider.dart';
import '../../providers/daily_message_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageState = ref.watch(dailyMessageProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final theme = Theme.of(context);

    final messageId = messageState.messageId;
    final isBookmarked =
        messageId != null && bookmarks.contains(messageId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Today\'s comfort message',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: const Color(0xFFF0E7DA).withOpacity(0.92),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Press Power to tune in and receive a single message for today.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFE6DCCF).withOpacity(0.92),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        if (!messageState.hasTuned)
          Text(
            'The frequency is quiet. Tap Power to begin.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFE6DCCF).withOpacity(0.92),
              height: 1.35,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                messageState.message ?? '',
                style: theme.textTheme.titleLarge?.copyWith(
                  height: 1.35,
                  color: const Color(0xFFF0E7DA).withOpacity(0.92),
                ),
              ),
              const SizedBox(height: 12),
              if (messageState.isRepeat)
                Text(
                  'Same signal as earlier today.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE6DCCF).withOpacity(0.92),
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: messageId == null
                      ? null
                      : () => ref
                          .read(bookmarksProvider.notifier)
                          .toggle(messageId),
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Colors.amber : Colors.white70,
                  ),
                  label: Text(
                    isBookmarked ? 'Bookmarked' : 'Bookmark this',
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
