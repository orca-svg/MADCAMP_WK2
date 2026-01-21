import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/bookmarks_provider.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // ✅ bookmarksProvider가 Set/List 무엇이든 iterable이면 동작하도록 처리
    final bookmarksState = ref.watch(bookmarksProvider);
    final items = _normalizeBookmarks(bookmarksState);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: _HeaderCard(
                  title: '북마크',
                  subtitle: '북마크한 위로 문구 ${items.length}개',
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
                    child: Text(
                      '아직 북마크한 위로 문구가 없어요.\n홈에서 마음에 드는 문구를 북마크해 보세요.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD7CCB9).withOpacity(0.86),
                        height: 1.35,
                      ),
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
                    return _BookmarkAdviceCard(
                      content: it.content ?? '(내용을 불러올 수 없어요)',
                      sentAtText: it.sentAtText,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// bookmarksProvider의 상태가 다음 중 무엇이든 최대한 표시되도록 정규화합니다.
  /// - List<String> (content 저장)
  /// - Set<String>  (content 저장)
  /// - List<Map> / Set<Map> (id/content/sentAt 등 저장)
  /// - List<int>/Set<int> (id만 저장) => content는 null
  List<_BookmarkAdviceView> _normalizeBookmarks(Object state) {
    if (state is Iterable) {
      return state.map<_BookmarkAdviceView>((e) {
        // Map 형태라면 content/sentAt 우선 사용
        if (e is Map) {
          final content = (e['content'] ?? e['text'] ?? e['message'])?.toString();
          final sentAt = (e['sentAt'] ?? e['date'] ?? e['createdAt'])?.toString();
          return _BookmarkAdviceView(
            content: content,
            sentAtText: sentAt != null && sentAt.isNotEmpty ? sentAt : null,
          );
        }

        // String이면 content로 간주
        if (e is String) {
          return _BookmarkAdviceView(content: e, sentAtText: null);
        }

        // int 등 id만 있으면 content는 알 수 없음
        return const _BookmarkAdviceView(content: null, sentAtText: null);
      }).toList();
    }

    return const <_BookmarkAdviceView>[];
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
    required this.sentAtText,
  });

  final String content;
  final String? sentAtText;

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
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF2EBDD).withOpacity(0.92),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.bookmark_rounded, size: 16, color: Color(0xFFD7CCB9)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sentAtText ?? '저장됨',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD7CCB9).withOpacity(0.72),
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookmarkAdviceView {
  const _BookmarkAdviceView({
    required this.content,
    required this.sentAtText,
  });

  final String? content;
  final String? sentAtText;
}
