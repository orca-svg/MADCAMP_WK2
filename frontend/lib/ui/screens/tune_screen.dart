import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/board_repository.dart';
import '../../providers/board_provider.dart';
import '../../providers/theater_provider.dart';

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

/// ✅ 송신 오버레이가 "충분히" 보이도록 하는 타이밍 세트
const _txTotalDuration = Duration(milliseconds: 2100);
const _txFadeInMs = 260; // 처음 등장
const _txMinShowMs = 1350; // 최소 체류(이 시간 전에는 theater로 안 넘어감)
const _txAfterEnterDelayMs = 120; // theater enter 직후 오버레이 정리 딜레이

class TuneScreen extends ConsumerStatefulWidget {
  const TuneScreen({super.key});

  @override
  ConsumerState<TuneScreen> createState() => _TuneScreenState();
}

class _TuneScreenState extends ConsumerState<TuneScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _storyController = TextEditingController();
  final _random = Random();

  bool _publishToBoard = false;
  final List<String> _selectedTags = [];
  DateTime? _lastTagSnackAt;

  // ✅ 송수신 오버레이 상태
  bool _isTransmitting = false;

  // ✅ 리플/페이드 진행 컨트롤러
  late final AnimationController _txController;

  @override
  void initState() {
    super.initState();
    _txController = AnimationController(
      vsync: this,
      duration: _txTotalDuration,
    );
  }

  @override
  void dispose() {
    _txController.dispose();
    _titleController.dispose();
    _storyController.dispose();
    super.dispose();
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
    if (_isTransmitting) return;

    final story = _storyController.text.trim();
    if (story.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사연을 입력해주세요.')),
      );
      return;
    }

    final startedAt = DateTime.now();

    // ✅ 1) 송신 오버레이 시작 (페이드 인 충분히 보이게)
    setState(() => _isTransmitting = true);
    _txController.stop();
    _txController.value = 0;
    unawaited(_txController.forward());

    // 페이드 인이 눈에 보이도록 아주 짧게 대기
    await Future<void>.delayed(const Duration(milliseconds: _txFadeInMs));
    if (!mounted) return;

    // ✅ 2) 데이터 처리/핀 생성 (기능 유지)
    final post = await ref.read(boardControllerProvider.notifier).submitStory(
          title: _titleController.text.trim(),
          body: story,
          tags: List<String>.from(_selectedTags),
          publish: _publishToBoard,
        );

    final allPosts = ref.read(boardControllerProvider).openPosts;
    final pins = _buildPins(allPosts, _publishToBoard ? post : null);

    // ✅ 3) 오버레이 최소 체류 시간 보장 (여기가 "너무 빨리 전환" 문제의 핵심 해결)
    final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    final remainMs = (_txMinShowMs - elapsedMs).clamp(0, _txMinShowMs);
    if (remainMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: remainMs));
      if (!mounted) return;
    }

    // ✅ 4) theater 진입
    ref.read(theaterProvider.notifier).enter(pins: pins);

    // ✅ 5) 오버레이 상태 정리(살짝만 여유 후 끄기)
    await Future<void>.delayed(
      const Duration(milliseconds: _txAfterEnterDelayMs),
    );
    if (!mounted) return;
    setState(() => _isTransmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final theaterActive = ref.watch(theaterProvider).isActive;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ✅ 작성 패널(기존 화면)
        IgnorePointer(
          ignoring: theaterActive || _isTransmitting,
          child: AnimatedOpacity(
            opacity: (theaterActive || _isTransmitting) ? 0 : 1,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: _ComposePanel(
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
            ),
          ),
        ),

        // ✅ 송수신 오버레이(검은 화면 + 중앙 문구 + 물결)
        if (_isTransmitting)
          Positioned.fill(
            child: _TransmitOverlay(
              controller: _txController,
              text: '주파수를 송신 중입니다.',
            ),
          ),
      ],
    );
  }

  List<StarPin> _buildPins(List<BoardPost> posts, BoardPost? newPost) {
    final buffer = List<BoardPost>.from(posts);
    if (newPost != null) {
      buffer.insert(0, newPost);
    }
    buffer.shuffle(_random);

    final selected = buffer.take(10).toList();
    final pins = selected
        .map(
          (post) => StarPin(
            id: post.id,
            title: post.title,
            preview: post.body,
            tags: post.tags.take(3).toList(),
          ),
        )
        .toList();

    if (pins.length < 10) {
      final gap = 10 - pins.length;
      for (int i = 0; i < gap; i++) {
        pins.add(
          StarPin(
            id: 'ghost_$i',
            title: '주파수 신호',
            preview: '잠시 연결되는 사연을 기다리고 있어요.',
            tags: const ['#그냥_들어줘 🎧'],
          ),
        );
      }
    }
    return pins;
  }
}

class _TransmitOverlay extends StatelessWidget {
  const _TransmitOverlay({
    required this.controller,
    required this.text,
  });

  final AnimationController controller;
  final String text;

  @override
  Widget build(BuildContext context) {
    // ✅ 페이드: In → Hold → Out
    final opacity = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.00, 0.18, curve: Curves.easeOut),
      reverseCurve: const Interval(0.82, 1.00, curve: Curves.easeIn),
    );

    // Interval로 "유지" 구간을 만들기 위해 TweenSequence 사용
    final holdOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: const Interval(0.00, 0.18, curve: Curves.easeOut))),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 64),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: const Interval(0.82, 1.00, curve: Curves.easeIn))),
        weight: 18,
      ),
    ]).animate(controller);

    return FadeTransition(
      opacity: holdOpacity,
      child: ColoredBox(
        color: Colors.black.withOpacity(0.92),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _RippleWaves(progress: controller),
                _TransmitTextCard(text: text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransmitTextCard extends StatelessWidget {
  const _TransmitTextCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1714).withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x2ED7CCB9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF2EBDD),
              fontFamily: _readableBodyFont,
            ),
      ),
    );
  }
}

class _RippleWaves extends StatelessWidget {
  const _RippleWaves({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(360, 360),
          painter: _RipplePainter(t: progress.value),
        );
      },
    );
  }
}

/// ✅ "계속 퍼지는" 느낌: t를 loop로 사용
class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // t(0..1)를 조금 빠르게 진행시키고, 3겹을 서로 다른 위상으로 반복
    final base = (t * 1.35) % 1.0;

    for (final phase in [0.0, 0.28, 0.56]) {
      final local = (base + phase) % 1.0;

      final eased = Curves.easeOutCubic.transform(local);
      final radius = lerpDouble(28, size.width * 0.48, eased)!;

      // 중앙은 진하고 밖으로 갈수록 옅게
      final alpha = (1.0 - local).clamp(0.0, 1.0);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lerpDouble(2.2, 0.7, eased)!
        ..color = const Color(0xFFF2EBDD).withOpacity(0.18 * alpha);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => oldDelegate.t != t;
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
                          const SizedBox(height: 10),
                          _TagSelectButton(
                            selectedCount: selectedTags.length,
                            onTap: onOpenTagSelector,
                          ),
                          if (selectedTags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _SelectedTags(tags: selectedTags),
                          ],
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

class _TagSelectButton extends StatelessWidget {
  const _TagSelectButton({
    required this.selectedCount,
    required this.onTap,
  });

  final int selectedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = '태그 선택 ($selectedCount/3)';
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
                        fontWeight: FontWeight.w800,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < tags.length; i++) ...[
            _SelectedTagChip(label: tags[i]),
            if (i != tags.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _SelectedTagChip extends StatelessWidget {
  const _SelectedTagChip({required this.label});

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
