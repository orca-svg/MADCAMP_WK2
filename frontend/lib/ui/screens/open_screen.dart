import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/board_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/post_preview_card.dart';

const _filterTags = [
  '전체',
  '#불안 😰',
  '#외로움 🌙',
  '#관계 🤝',
  '#가족 🏠',
  '#연애 💞',
  '#진로 🎯',
  '#학업 📚',
  '#일/번아웃 🔥',
  '#자존감 🌿',
  '#건강 🫧',
  '#후회/죄책감 🕯️',
  '#그냥_들어줘 🎧',
];

class OpenScreen extends ConsumerStatefulWidget {
  const OpenScreen({super.key});

  @override
  ConsumerState<OpenScreen> createState() => _OpenScreenState();
}

class _OpenScreenState extends ConsumerState<OpenScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _selectedTag = '전체';
  bool _didLoadOpen = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() => _query = '');
  }

  void _selectTag(String tag) {
    setState(() => _selectedTag = tag);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (!_didLoadOpen && authState.isSignedIn && !authState.isLoading) {
      _didLoadOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(boardControllerProvider.notifier).refreshOpen();
      });
    }
    final posts = ref.watch(boardControllerProvider).openPosts;
    final theme = Theme.of(context);
    final normalizedQuery = _query.toLowerCase();
    final filtered = posts.where((post) {
      final matchesQuery = normalizedQuery.isEmpty ||
          post.title.toLowerCase().contains(normalizedQuery) ||
          post.body.toLowerCase().contains(normalizedQuery);
      final matchesTag =
          _selectedTag == '전체' || post.tags.contains(_selectedTag);
      return matchesQuery && matchesTag;
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('열린 주파수', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text(
                  '다른 사람들의 주파수를 둘러보세요.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _OpenFilterHeaderDelegate(
            controller: _searchController,
            searchText: _searchController.text,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
            selectedTag: _selectedTag,
            onTagSelected: _selectTag,
            tags: _filterTags,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 10)),
        // ✅ Empty state when no posts
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.radio_outlined,
                      size: 48,
                      color: const Color(0xFFD7CCB9).withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '아직 열린 주파수에 글이 없어요.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFD7CCB9).withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = filtered[index];
                return PostPreviewCard(
                  title: post.title,
                  body: post.body,
                  createdAt: post.createdAt,
                  tags: post.tags,
                  onTap: () => context.go('/open/${post.id}'),
                );
              },
              childCount: filtered.length,
            ),
          ),
      ],
    );
  }
}

class _OpenFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _OpenFilterHeaderDelegate({
    required this.controller,
    required this.searchText,
    required this.onChanged,
    required this.onClear,
    required this.selectedTag,
    required this.onTagSelected,
    required this.tags,
  });

  final TextEditingController controller;
  final String searchText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String selectedTag;
  final ValueChanged<String> onTagSelected;
  final List<String> tags;

  @override
  double get minExtent => 102;

  @override
  double get maxExtent => 102;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final hasText = searchText.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        const baseHeight = 108.0;
        final scale = (constraints.maxHeight / baseHeight).clamp(0.5, 1.0);
        final paddingH = 14 * scale;
        final paddingTop = 8 * scale;
        // Reclaim bottom slack for the gap between search and tags.
        final paddingBottom = 0 * scale;
        final searchHeight = 40 * scale;
        final tagHeight = 28 * scale;
        final iconSize = 18 * scale;
        final textSize = 13 * scale;
        final betweenGap = 8 * scale;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              paddingH,
              paddingTop,
              paddingH,
              paddingBottom,
            ),
            decoration: BoxDecoration(
              color: const Color(0xE61F1A17),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: searchHeight,
                        width: double.infinity,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10 * scale),
                          decoration: BoxDecoration(
                            color: const Color(0x24171411),
                            borderRadius: BorderRadius.circular(14 * scale),
                            border: Border.all(
                              color: const Color(0x2ED7CCB9),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: iconSize,
                                color:
                                    const Color(0xFFD7CCB9).withOpacity(0.85),
                              ),
                              SizedBox(width: 8 * scale),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  onChanged: onChanged,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: TextStyle(
                                    fontSize: textSize,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF2EBDD),
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    isCollapsed: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: '제목/내용 검색',
                                    hintStyle: TextStyle(
                                      fontSize: textSize,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFD7CCB9)
                                          .withOpacity(0.70),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              if (hasText)
                                GestureDetector(
                                  onTap: onClear,
                                  child: SizedBox(
                                    width: 28 * scale,
                                    height: 28 * scale,
                                    child: Center(
                                      child: Icon(Icons.close, size: iconSize),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: betweenGap),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            height: tagHeight,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (int i = 0; i < tags.length; i++) ...[
                                    _FilterChip(
                                      label: tags[i],
                                      selected: tags[i] == selectedTag,
                                      onTap: () => onTagSelected(tags[i]),
                                      scale: scale,
                                    ),
                                    if (i != tags.length - 1)
                                      SizedBox(width: 8 * scale),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 1,
                    color: const Color(0x1FD7CCB9),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(covariant _OpenFilterHeaderDelegate oldDelegate) {
    return oldDelegate.searchText != searchText ||
        oldDelegate.selectedTag != selectedTag ||
        oldDelegate.tags != tags;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scale,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final height = 28 * scale;
    final radius = 14 * scale;
    final fontSize = (12 * scale).clamp(10.0, 12.0);
    final paddingH = 10 * scale;
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(height: height),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: paddingH),
            decoration: BoxDecoration(
              color:
                  selected ? const Color(0x661F1A17) : const Color(0x24171411),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected
                    ? const Color(0xFFD7CCB9)
                    : const Color(0x2ED7CCB9),
                width: selected ? 1.2 : 1.0,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xF2F2EBDD)
                      : const Color(0xE6D7CCB9),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
