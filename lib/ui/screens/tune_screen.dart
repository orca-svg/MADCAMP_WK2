import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/board_repository.dart';
import '../../providers/board_provider.dart';

enum _TuneStage { compose, transmit, starboard }

const _readableBodyFont = 'ChosunCentennial';

const _tagOptions = [
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

class TuneScreen extends ConsumerStatefulWidget {
  const TuneScreen({super.key});

  @override
  ConsumerState<TuneScreen> createState() => _TuneScreenState();
}

class _TuneScreenState extends ConsumerState<TuneScreen> {
  final _titleController = TextEditingController();
  final _storyController = TextEditingController();
  final _random = Random();
  final Map<String, Offset> _pinPositions = {};

  _TuneStage _stage = _TuneStage.compose;
  bool _publishToBoard = false;
  final List<String> _selectedTags = [];
  DateTime? _lastTagSnackAt;
  Timer? _transmitTimer;

  OverlayEntry? _popoverEntry;
  String? _selectedPostId;
  DateTime? _lastTapAt;

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    _transmitTimer?.cancel();
    _removePopover();
    super.dispose();
  }

  void _removePopover() {
    _popoverEntry?.remove();
    _popoverEntry = null;
    _selectedPostId = null;
  }

  bool _canShowTagSnack() {
    final last = _lastTagSnackAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.now().difference(last).inMilliseconds >= 2500;
  }

  void _showTagSnack() {
    if (!_canShowTagSnack()) return;
    _lastTagSnackAt = DateTime.now();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('태그는 최대 3개까지 선택할 수 있어요.')),
    );
  }

  void _toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      setState(() => _selectedTags.remove(tag));
      return;
    }
    if (_selectedTags.length >= 3) {
      _showTagSnack();
      return;
    }
    setState(() => _selectedTags.add(tag));
  }

  void _openTagSelectorSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final sheetHeight = MediaQuery.of(context).size.height * 0.52;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasSelection = _selectedTags.isNotEmpty;
            return Container(
              height: sheetHeight,
              decoration: const BoxDecoration(
                color: Color(0xFF1F1A17),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in _tagOptions)
                                _TagButton(
                                  label: tag,
                                  isSelected: _selectedTags.contains(tag),
                                  onTap: () {
                                    _toggleTag(tag);
                                    setModalState(() {});
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (hasSelection)
                        SizedBox(
                          height: 44,
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _selectedTags.clear());
                              setModalState(() {});
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('선택 해제'),
                          ),
                        ),
                      if (hasSelection) const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('완료'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _send() async {
    final story = _storyController.text.trim();
    if (story.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사연을 입력해주세요.')),
      );
      return;
    }

    final post = ref.read(boardControllerProvider.notifier).submitStory(
          title: _titleController.text.trim(),
          body: story,
          tags: List<String>.from(_selectedTags),
          publish: _publishToBoard,
        );

    setState(() {
      _stage = _TuneStage.transmit;
      if (_publishToBoard) {
        _selectedPostId = post.id;
      }
    });

    _transmitTimer?.cancel();
    _transmitTimer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => _stage = _TuneStage.starboard);
    });
  }

  void _showPopover(BoardPost post, LayerLink link) {
    _removePopover();
    _selectedPostId = post.id;
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;
    _popoverEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: ModalBarrier(
                dismissible: true,
                color: Colors.transparent,
                onDismiss: _removePopover,
              ),
            ),
            CompositedTransformFollower(
              link: link,
              followerAnchor: Alignment.bottomCenter,
              targetAnchor: Alignment.topCenter,
              offset: const Offset(0, -12),
              showWhenUnlinked: false,
              child: Material(
                color: Colors.transparent,
                child: _StarPopover(post: post),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_popoverEntry!);
  }

  void _handlePinTap(BoardPost post, LayerLink link) {
    final now = DateTime.now();
    if (_selectedPostId == post.id && _lastTapAt != null) {
      if (now.difference(_lastTapAt!).inMilliseconds <= 900) {
        _removePopover();
        if (mounted) {
          context.go('/open/${post.id}');
        }
        return;
      }
    }
    _lastTapAt = now;
    _showPopover(post, link);
  }

  Offset _pinOffsetFor(BoardPost post, Size size, int index) {
    final existing = _pinPositions[post.id];
    if (existing != null) return existing;
    final safeWidth = size.width - 48;
    final safeHeight = size.height - 140;
    final x = 24 + _random.nextDouble() * safeWidth;
    final y = 48 + _random.nextDouble() * safeHeight;
    final offset = Offset(x, y);
    _pinPositions[post.id] = offset;
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posts = ref.watch(boardControllerProvider).openPosts;
    final isTransmit = _stage == _TuneStage.transmit;
    final showTheater = _stage != _TuneStage.compose;
    final zoomedOut = _stage != _TuneStage.compose;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;
        final translateY = 180 / height;
        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: showTheater ? 1 : 0,
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutCubic,
                child: Image.asset(
                  'assets/images/frequency_theater_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: isTransmit ? 1 : 0,
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutCubic,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(0x33000000),
                        Color(0x66000000),
                      ],
                      radius: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 620),
                curve: Curves.easeInOutCubic,
                height: zoomedOut ? height * 0.72 : height,
                width: width,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  scale: zoomedOut ? 0.78 : 1.0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    offset: zoomedOut ? Offset(0, translateY) : Offset.zero,
                    child: IgnorePointer(
                      ignoring: _stage != _TuneStage.compose,
                      child: _stage == _TuneStage.compose
                          ? _ComposePanel(
                              theme: theme,
                              titleController: _titleController,
                              storyController: _storyController,
                              publishToBoard: _publishToBoard,
                              onPublishChanged: (value) {
                                setState(() => _publishToBoard = value);
                              },
                              selectedTags: _selectedTags,
                              onOpenTagSelector: _openTagSelectorSheet,
                              onSend: _send,
                            )
                          : const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            if (_stage == _TuneStage.starboard)
              Positioned.fill(
                child: _StarBoard(
                  posts: posts,
                  onPinTap: _handlePinTap,
                  pinOffsetFor: (post, index) =>
                      _pinOffsetFor(post, Size(width, height), index),
                ),
              ),
            if (isTransmit)
              Positioned(
                top: 120,
                left: 24,
                right: 24,
                child: _TransmitBanner(theme: theme),
              ),
          ],
        );
      },
    );
  }
}

class _ComposePanel extends StatelessWidget {
  const _ComposePanel({
    required this.theme,
    required this.titleController,
    required this.storyController,
    required this.publishToBoard,
    required this.onPublishChanged,
    required this.selectedTags,
    required this.onOpenTagSelector,
    required this.onSend,
  });

  final ThemeData theme;
  final TextEditingController titleController;
  final TextEditingController storyController;
  final bool publishToBoard;
  final ValueChanged<bool> onPublishChanged;
  final List<String> selectedTags;
  final VoidCallback onOpenTagSelector;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Text('주파수 조절', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    '사연을 입력하면 잠시 송수신 화면으로 전환됩니다.',
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _TagSelectButton(
                    selectedCount: selectedTags.length,
                    onTap: onOpenTagSelector,
                  ),
                ),
                if (selectedTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _SelectedTags(tags: selectedTags),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: LayoutBuilder(
                    builder: (context, formConstraints) {
                      final availableHeight = formConstraints.hasBoundedHeight
                          ? formConstraints.maxHeight
                          : constraints.maxHeight;
                      final clampedHeight =
                          (availableHeight * 0.46).clamp(120.0, 220.0);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: '사연 제목 ',
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: clampedHeight,
                            child: TextFormField(
                              controller: storyController,
                              decoration: const InputDecoration(
                                labelText: '사연을 들려주세요',
                                alignLabelWithHint: true,
                              ),
                              maxLines: null,
                              expands: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 44,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '게시판에 공유하기',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                CupertinoSwitch(
                                  value: publishToBoard,
                                  onChanged: onPublishChanged,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: onSend,
                              child: const Text('보내기'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransmitBanner extends StatelessWidget {
  const _TransmitBanner({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xCC1F1A17),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
      ),
      child: Center(
        child: Text(
          '잠시 송수신 화면으로 전환됩니다.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF2EBDD),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TagSelectButton extends StatelessWidget {
  const _TagSelectButton({
    required this.selectedCount,
    required this.onTap,
  });

  final int selectedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = selectedCount == 0
        ? '태그 선택 (선택)'
        : '태그 선택 ($selectedCount/3)';
    return SizedBox(
      height: 44,
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xE6D7CCB9),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.expand_more,
                    size: 18,
                    color: Color(0xFFD7CCB9),
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

class _TagButton extends StatelessWidget {
  const _TagButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFD7CCB9)
                : const Color(0x2ED7CCB9),
            width: isSelected ? 1.2 : 1.0,
          ),
          backgroundColor:
              isSelected ? const Color(0x661F1A17) : const Color(0x24171411),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? const Color(0xF2F2EBDD)
                : const Color(0xE6D7CCB9),
          ),
        ),
      ),
    );
  }
}

class _SelectedTags extends StatelessWidget {
  const _SelectedTags({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags.take(3))
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0x33171411),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xE6F2EBDD),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StarBoard extends StatelessWidget {
  const _StarBoard({
    required this.posts,
    required this.onPinTap,
    required this.pinOffsetFor,
  });

  final List<BoardPost> posts;
  final void Function(BoardPost post, LayerLink link) onPinTap;
  final Offset Function(BoardPost post, int index) pinOffsetFor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (int i = 0; i < posts.length; i++)
              _StarPin(
                key: ValueKey(posts[i].id),
                post: posts[i],
                offset: pinOffsetFor(posts[i], i),
                onTap: onPinTap,
              ),
          ],
        );
      },
    );
  }
}

class _StarPin extends StatefulWidget {
  const _StarPin({
    super.key,
    required this.post,
    required this.offset,
    required this.onTap,
  });

  final BoardPost post;
  final Offset offset;
  final void Function(BoardPost post, LayerLink link) onTap;

  @override
  State<_StarPin> createState() => _StarPinState();
}

class _StarPinState extends State<_StarPin> {
  final LayerLink _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.offset.dx,
      top: widget.offset.dy,
      child: CompositedTransformTarget(
        link: _link,
        child: GestureDetector(
          onTap: () => widget.onTap(widget.post, _link),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFF2EBDD),
                      Color(0x99D7CCB9),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66F2EBDD),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPopover extends StatelessWidget {
  const _StarPopover({required this.post});

  final BoardPost post;

  @override
  Widget build(BuildContext context) {
    final tags = post.tags.take(3).toList();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xE61F1A17),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in tags) _MiniTagChip(text: tag),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(post.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.75),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: _readableBodyFont,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '한 번 더 누르면 상세보기',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.75),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime time) {
  final year = time.year.toString().padLeft(4, '0');
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '$year.$month.$day';
}

class _MiniTagChip extends StatelessWidget {
  const _MiniTagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0x33171411),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xE6F2EBDD),
          ),
        ),
      ),
    );
  }
}
