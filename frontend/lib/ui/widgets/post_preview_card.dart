import 'package:flutter/material.dart';

const _readableBodyFont = 'ChosunCentennial';

class PostPreviewCard extends StatelessWidget {
  const PostPreviewCard({
    super.key,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.tags,
    this.likeCount = 0,
    this.isAdopted = false,
    this.onTap,
  });

  final String title;
  final String body;
  final DateTime createdAt;
  final List<String> tags;
  final int likeCount;
  final bool isAdopted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final previewColor = const Color(0xCCF2EBDD);
    final dateColor = const Color(0x88D7CCB9);
    final tagColor = const Color(0xAAD7CCB9);
    final statColor = const Color(0x99D7CCB9);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: const Color(0x1A171411),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1FD7CCB9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: title + adopted icon
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _readableBodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF2EBDD),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isAdopted ? Icons.verified : Icons.verified_outlined,
                      size: 16,
                      color: isAdopted
                          ? const Color(0xFFF2EBDD).withValues(alpha: 0.95)
                          : const Color(0xFFD7CCB9).withValues(alpha: 0.40),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Second line: preview
                Text(
                  body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _readableBodyFont,
                    fontSize: 12,
                    height: 1.35,
                    color: previewColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Third line: tags + date
                Row(
                  children: [
                    if (tags.isNotEmpty) ...[
                      Flexible(
                        child: _TagRow(tags: tags, textColor: tagColor),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        fontFamily: _readableBodyFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: dateColor,
                      ),
                    ),
                    const Spacer(),
                    // Stats: like count
                    Icon(Icons.favorite_border, size: 12, color: statColor),
                    const SizedBox(width: 3),
                    Text(
                      '$likeCount',
                      style: TextStyle(fontSize: 10, color: statColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
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
