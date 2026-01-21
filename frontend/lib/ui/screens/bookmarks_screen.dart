import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/bookmarks_provider.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Watch state to trigger rebuild on changes
    ref.watch(bookmarksProvider);
    // Get metadata list from controller
    final items = ref.read(bookmarksProvider.notifier).getMetadataList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: _HeaderCard(
                  title: '북마크한 위로',
                  subtitle: '저장한 문구 ${items.length}개',
                  onBack: () => context.pop(),
                ),
              ),
            ),
            if (items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x14171411),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '아직 북마크한 위로가 없어요.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF2EBDD).withOpacity(0.90),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '홈에서 마음에 드는 문구를 저장해 보세요.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD7CCB9).withOpacity(0.72),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final it = items[index];
                    final hasContent = it.content.isNotEmpty;
                    return _BookmarkAdviceCard(
                      content: hasContent ? it.content : '(내용을 불러올 수 없어요)',
                      bookmarkedAt: it.bookmarkedAt,
                      onRemove: () => _showRemoveDialog(context, ref, it.adviceId),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, WidgetRef ref, String adviceId) {
    HapticFeedback.lightImpact();
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2520),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '북마크를 해제하시겠습니까?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFF2EBDD),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFD7CCB9),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '북마크 해제하기',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF6B5B),
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(bookmarksProvider.notifier).remove(adviceId);
      }
    });
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xE61F1A17),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22D7CCB9), width: 1),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x14171411),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFFD7CCB9),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (theme.textTheme.headlineSmall ?? theme.textTheme.titleLarge)?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFF2EBDD),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD7CCB9).withOpacity(0.80),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkAdviceCard extends StatelessWidget {
  const _BookmarkAdviceCard({
    required this.content,
    required this.bookmarkedAt,
    required this.onRemove,
  });

  final String content;
  final DateTime bookmarkedAt;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0x14171411),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘의 위로',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD7CCB9).withOpacity(0.72),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF2EBDD).withOpacity(0.92),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _BookmarkToggle(onTap: onRemove),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatBookmarkedAt(bookmarkedAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD7CCB9).withOpacity(0.60),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBookmarkedAt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y.$m.$d에 북마크함';
  }
}

class _BookmarkToggle extends StatelessWidget {
  const _BookmarkToggle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(
            Icons.bookmark,
            size: 22,
            color: Color(0xFFE0B66B),
          ),
        ),
      ),
    );
  }
}
