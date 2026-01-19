import 'package:flutter/material.dart';

const _readableBodyFont = 'ChosunCentennial';

class PostPreviewCard extends StatelessWidget {
  const PostPreviewCard({
    super.key,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.tags,
    this.onTap,
  });

  final String title;
  final String body;
  final DateTime createdAt;
  final List<String> tags;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyColor = const Color(0xFFF2EBDD).withOpacity(0.90);
    final dateColor = const Color(0xFFD7CCB9).withOpacity(0.75);
    final tagColor = const Color(0xFFD7CCB9).withOpacity(0.92);

    return Container(
      margin: const EdgeInsets.all(10),
      child: Material(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: _readableBodyFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: const Color(0xFFF2EBDD),
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _TagRow(tags: tags, textColor: tagColor),
                  const SizedBox(height: 10),
                ],
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: _readableBodyFont,
                    fontSize: 13,
                    height: 1.35,
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatTime(createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: _readableBodyFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: dateColor,
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

  String _formatTime(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags, required this.textColor});

  final List<String> tags;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < tags.length; i++) ...[
            _TagChip(text: tags[i], textColor: textColor),
            if (i != tags.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text, required this.textColor});

  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 110),
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0x24171411),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: _readableBodyFont,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
