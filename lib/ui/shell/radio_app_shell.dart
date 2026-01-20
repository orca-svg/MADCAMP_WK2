import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/radio_tone.dart';
import '../widgets/retro_indicator_bar.dart';
import '../widgets/speaker_content_area.dart';
import '../../providers/theater_provider.dart';

class RadioAppShell extends ConsumerStatefulWidget {
  const RadioAppShell({
    super.key,
    this.child,
    this.tabViews,
    required this.indicatorLabel,
    this.tabIndex = 0,
    this.indicatorLeftReserved = RadioTone.indicatorLeftSlot,
    this.indicatorLabelPadding = RadioTone.indicatorLabelPadLeft,
    this.enableIndicatorNudge = true,
    this.needlePositionOverride,
    this.needleColor,
    this.showControls = true,
    this.powerOn = false,
    this.isLoggedIn = true,
    this.onPrev,
    this.onPower,
    this.onNext,
  });

  final Widget? child;
  final List<Widget>? tabViews;
  final String indicatorLabel;
  final int tabIndex;
  final double indicatorLeftReserved;
  final double indicatorLabelPadding;
  final bool enableIndicatorNudge;
  final double? needlePositionOverride;
  final Color? needleColor;
  final bool showControls;
  final bool powerOn;
  final bool isLoggedIn;
  final VoidCallback? onPrev;
  final VoidCallback? onPower;
  final VoidCallback? onNext;

  @override
  ConsumerState<RadioAppShell> createState() => _RadioAppShellState();
}

class _RadioAppShellState extends ConsumerState<RadioAppShell> {
  DateTime? _lastPowerOffSnackAt;
  bool _powerOffNoticeVisible = false;
  Timer? _noticeTimer;
  final Map<String, Offset> _starPositions = {};
  final Map<String, LayerLink> _starLinks = {};
  DateTime? _lastPinTapAt;
  String? _lastPinId;
  bool _wasTheaterActive = false;
  OverlayEntry? _bubbleEntry;
  String? _bubbleStarId;

  bool _canShowPowerOffSnack() {
    final last =
        _lastPowerOffSnackAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.now().difference(last).inMilliseconds >= 2500;
  }

  void _showPowerOffSnack(BuildContext context) {
    if (!_canShowPowerOffSnack()) return; // 2.5s throttle.
    _lastPowerOffSnackAt = DateTime.now();
    _noticeTimer?.cancel();
    setState(() {
      _powerOffNoticeVisible = true;
    });
    _noticeTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _powerOffNoticeVisible = false;
      });
    });
  }

  void _handlePrev(BuildContext context) {
    if (!widget.powerOn) {
      _showPowerOffSnack(context);
      return;
    }
    widget.onPrev?.call();
  }

  void _handleNext(BuildContext context) {
    if (!widget.powerOn) {
      _showPowerOffSnack(context);
      return;
    }
    widget.onNext?.call();
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final theater = ref.watch(theaterProvider);
    final theaterController = ref.read(theaterProvider.notifier);
    if (theater.isActive != _wasTheaterActive) {
      _starPositions.clear();
      _starLinks.clear();
      _lastPinTapAt = null;
      _lastPinId = null;
      _closeBubble();
      _wasTheaterActive = theater.isActive;
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _TheaterBackground(isActive: theater.isActive),
          ),
          if (!theater.isActive)
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(child: RadioFrameBackground()),
                  SafeArea(
                    child: Padding(
                      padding: RadioTone.shellPadding,
                      child: _RadioLayout(
                        indicatorLabel: widget.indicatorLabel,
                        tabIndex: widget.tabIndex,
                        indicatorLeftReserved: widget.indicatorLeftReserved,
                        indicatorLabelPadding: widget.indicatorLabelPadding,
                        enableIndicatorNudge: widget.enableIndicatorNudge,
                        needlePositionOverride: widget.needlePositionOverride,
                        needleColor: widget.needleColor,
                        showControls: widget.showControls,
                        powerOn: widget.powerOn,
                        isLoggedIn: widget.isLoggedIn,
                        onPrev: widget.onPrev == null
                            ? null
                            : () => _handlePrev(context),
                        onPower: widget.onPower,
                        onNext: widget.onNext == null
                            ? null
                            : () => _handleNext(context),
                        child: widget.child,
                        tabViews: widget.tabViews,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Positioned(
              right: 18,
              bottom: 170,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: theaterController.exit,
                child: _TheaterMiniRadio(label: widget.indicatorLabel),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !theater.isActive,
              child: AnimatedOpacity(
                opacity: theater.isActive ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: _StarPinsOverlay(
                  pins: theater.pins,
                  positions: _starPositions,
                  links: _starLinks,
                  onSelect: (pin) => _handlePinTap(
                    context,
                    pin,
                    theaterController,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: safeTop + 6,
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedSlide(
                offset:
                    _powerOffNoticeVisible ? Offset.zero : const Offset(0, -0.6),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _powerOffNoticeVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 140),
                  child: _PowerOffNotice(
                    textStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: const Color(0xFFF3E7D3)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePinTap(
    BuildContext context,
    StarPin pin,
    TheaterController controller,
  ) {
    final now = DateTime.now();
    final isSame = _lastPinId == pin.id;
    if (isSame && _lastPinTapAt != null) {
      if (now.difference(_lastPinTapAt!).inMilliseconds <= 900) {
        _closeBubble();
        if (!_hasPostForPin(context, pin)) {
          _showMissingDetailSheet(context);
          return;
        }
        // ✅ theater 모드에서는 Shell이 child를 안 그리므로, 상세로 가기 전 theater를 끕니다.
        controller.exit();
        // ✅ exit로 프레임이 한번 돈 뒤에 push하는 게 안정적입니다.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push('/open/${pin.id}?from=theater');
        });
        return;
      }
    }
    _lastPinId = pin.id;
    _lastPinTapAt = now;
    if (_bubbleStarId == pin.id) {
      _closeBubble();
      return;
    }
    _showBubble(context, pin);
  }

  bool _hasPostForPin(BuildContext context, StarPin pin) {
    return pin.id.isNotEmpty && !pin.id.startsWith('ghost_');
  }

  void _showMissingDetailSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: const BoxDecoration(
            color: Color(0xE61F1A17),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '아직 상세 글이 준비되지 않았어요.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF2EBDD),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0x2ED7CCB9),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('돌아가기'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBubble(BuildContext context, StarPin pin) {
    final shellContext = context; // ✅ overlay builder context 대신 이걸 사용
    _closeBubble();
    final link = _starLinks[pin.id];
    if (link == null) return;
    final starOffset = _starPositions[pin.id];
    if (starOffset == null) return;
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    _bubbleStarId = pin.id;
    final navContext = this.context; // ✅ Overlay context 말고 State context를 캡처
    final theaterController = ref.read(theaterProvider.notifier); // ✅ 여기서 컨트롤러 캡처
    final screen = MediaQuery.of(context).size;
    const bubbleW = 220.0;
    const bubbleH = 140.0;
    final miniRect = Rect.fromLTWH(
      screen.width - 18 - 220,
      screen.height - 70 - 72,
      220,
      72,
    );
    final offset = _bubbleOffsetFor(
      starOffset,
      screen,
      bubbleW,
      bubbleH,
      miniRect,
    );
    _bubbleEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeBubble,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: link,
              offset: offset,
              showWhenUnlinked: false,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {
                    _closeBubble();
                    if (pin.title.trim().isEmpty &&
                        pin.preview.trim().isEmpty) {
                      _closeBubble();
                      return;
                    }
                    ref.read(theaterProvider.notifier).exit();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      shellContext.push('/open/${pin.id}?from=theater');
                    });
                  },
                  child: _StarBubble(pin: pin),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_bubbleEntry!);
  }

  Offset _bubbleOffsetFor(
  Offset starOffset,
  Size screen,
  double bubbleW,
  double bubbleH,
  Rect miniRect,
) {
  const margin = 16.0;
    // _StarPin에서 타겟 박스가 44x44이고,
    // starOffset은 "중심"으로 쓰고 있으므로,
    // CompositedTransformTarget(좌상단 기준)으로 환산하기 위한 보정값입니다.
    const targetHalf = 22.0;
    final targetTopLeft = Offset(starOffset.dx - targetHalf, starOffset.dy - targetHalf);


  // 화면을 기준으로 별의 위치를 분류
  final isLeft = starOffset.dx < screen.width * 0.33;
  final isRight = starOffset.dx > screen.width * 0.67;
  final isTop = starOffset.dy < screen.height * 0.28;
  final isBottom = starOffset.dy > screen.height * 0.72;

  // 기본: 별 "위"에 말풍선(중앙 정렬)
  double dx = -bubbleW / 2;
  double dy = -bubbleH - 12;

  // 좌측이면 → 오른쪽에
  if (isLeft) {
    dx = 30;
    dy = -bubbleH / 2;
  }

  // 우측이면 → 왼쪽에
  if (isRight) {
    dx = -bubbleW - 16;
    dy = -bubbleH / 2;
  }

  // 상단이면 → 아래에
  if (isTop) {
    dx = -bubbleW / 2;
    dy = 16;
  }

  // 하단이면 → 위에(기본과 비슷하지만 좀 더 여유)
  if (isBottom) {
    dx = -bubbleW / 2;
    dy = -bubbleH - 16;
  }

  // 1) 화면 안으로 clamp (absolute 기준)
  final absX = (starOffset.dx + dx).clamp(margin, screen.width - bubbleW - margin);
  final absY = (starOffset.dy + dy).clamp(margin, screen.height - bubbleH - margin);

  // 2) mini radio 영역과 겹치면 위로 올리기
  final bubbleBottom = absY + bubbleH;
  if (bubbleBottom > miniRect.top - 8) {
    final newAbsY = (miniRect.top - bubbleH - 12).clamp(margin, screen.height - bubbleH - margin);
    return Offset(absX - targetTopLeft.dx, newAbsY - targetTopLeft.dy);
  }

  return Offset(absX - targetTopLeft.dx, absY - targetTopLeft.dy);
}

  void _closeBubble() {
    _bubbleEntry?.remove();
    _bubbleEntry = null;
    _bubbleStarId = null;
  }
}

class _TheaterBackground extends StatelessWidget {
  const _TheaterBackground({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isActive ? 1 : 0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/frequency_theater_bg.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0.0, -0.15),
          ),
          Container(color: Colors.black.withOpacity(0.18)),
        ],
      ),
    );
  }
}

class _StarPinsOverlay extends StatelessWidget {
  const _StarPinsOverlay({
    required this.pins,
    required this.positions,
    required this.links,
    required this.onSelect,
  });

  final List<StarPin> pins;
  final Map<String, Offset> positions;
  final Map<String, LayerLink> links;
  final ValueChanged<StarPin> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final area = Rect.fromLTWH(
          20,
          90,
          width - 40,
          height - 90 - 300,
        );
        return Stack(
          children: [
            for (final pin in pins)
              _StarPin(
                key: ValueKey(pin.id),
                pin: pin,
                offset: positions.putIfAbsent(
                  pin.id,
                  () => _randomOffset(pin.id, area),
                ),
                link: links.putIfAbsent(pin.id, () => LayerLink()),
                onTap: () => onSelect(pin),
              ),
          ],
        );
      },
    );
  }

  Offset _randomOffset(String seed, Rect area) {
    final rand = Random();
    final x = area.left + rand.nextDouble() * area.width;
    final y = area.top + rand.nextDouble() * area.height;
    return Offset(x, y);
  }
}

class _StarPin extends StatelessWidget {
  const _StarPin({
    super.key,
    required this.pin,
    required this.offset,
    required this.link,
    required this.onTap,
  });

  final StarPin pin;
  final Offset offset;
  final LayerLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rand = Random(pin.id.hashCode);
        final size = 10 + rand.nextInt(5);
        final blur = 6 + rand.nextInt(5);
    final opacity = 0.65 + rand.nextDouble() * 0.25;
    return Positioned(
      left: offset.dx - 22,
      top: offset.dy - 22,
      child: CompositedTransformTarget(
        link: link,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: size.toDouble(),
                height: size.toDouble(),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF2EBDD).withOpacity(opacity),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFF2EBDD).withOpacity(opacity),
                      blurRadius: blur.toDouble(),
                      spreadRadius: 1.5,
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

class _TheaterMiniRadio extends StatelessWidget {
  const _TheaterMiniRadio({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const outerRadius = 12.0;
    const borderW = 1.0;
    const inset = 1.0;
    const width = 220.0;
    const height = 72.0;

    final innerRadius = outerRadius - inset;

return ClipRRect(
  borderRadius: BorderRadius.circular(outerRadius),
  child: Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      // ✅ 검정 비침 방지(인셋 영역 채우기)
      color: const Color(0xFFF2EBDD),
      borderRadius: BorderRadius.circular(outerRadius),
      border: Border.all(
        color: const Color(0xFFD7CCB9).withOpacity(0.95),
        width: borderW,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(inset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1) wood + 내용
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/textures/wood_grain.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 6, child: _MiniIndicator(label: label)),
                        const SizedBox(width: 8),
                        const Expanded(flex: 8, child: _MiniSpeakerBlank()),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: const IgnorePointer(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _MiniControlButton(icon: Icons.chevron_left),
                                    SizedBox(width: 6),
                                    _MiniControlButton(
                                      icon: Icons.power_settings_new,
                                      isPower: true,
                                    ),
                                    SizedBox(width: 6),
                                    _MiniControlButton(icon: Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(flex: 8, child: SizedBox()),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2) ✅ 우측-하단 "비네팅" (우하단에 그늘이 몰리게)
            //    - 중심을 bottomRight로 두고, 우하단으로 갈수록 어두워짐
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomRight,
                      radius: 1.05,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.12),
                        Colors.black.withOpacity(0.26),
                      ],
                      stops: const [0.0, 0.55, 0.78, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3) ✅ 하이라이트도 반영: 좌상단에서 빛이 들어오는 느낌
            //    - topLeft에 밝은 광택, 중앙으로 갈수록 사라짐
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 0.95,
                      colors: [
                        Colors.white.withOpacity(0.16),
                        Colors.white.withOpacity(0.06),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 0.70],
                    ),
                  ),
                ),
              ),
            ),

            // 4) ✅ 안쪽 림 하이라이트(마감선)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(innerRadius),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.10),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),

            // (선택) ✅ 우하단 림 살짝 더 눌러서 깊이감 강화하고 싶으면 추가
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(innerRadius),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
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
}

class _MiniIndicator extends StatelessWidget {
  const _MiniIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 2, 6, 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: Color(0xFFF2EBDD),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 6,
            child: Stack(
              children: [
                Row(
                  children: [
                    for (int i = 0; i < 8; i++) ...[
                      Container(
                        width: 2,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      if (i != 7) const SizedBox(width: 3),
                    ],
                    const SizedBox(width: 6),
                  ],
                ),
                Positioned(
                  top: 0,
                  left: 14,
                  child: Container(
                    width: 2,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(2),
                    ),
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

class _MiniSpeakerBlank extends StatelessWidget {
  const _MiniSpeakerBlank();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 30,
        width: 82,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/textures/fabric_grille.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0x66000000),
              BlendMode.multiply,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniControlButton extends StatelessWidget {
  const _MiniControlButton({
    required this.icon,
    this.isPower = false,
  });

  final IconData icon;
  final bool isPower;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFFF2E8D6).withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: 12,
          color: isPower ? const Color(0xFFD94A3A) : const Color(0xFF3A2A1D),
        ),
      ),
    );
  }
}

class _StarBubble extends StatelessWidget {
  const _StarBubble({required this.pin});

  final StarPin pin;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220, maxHeight: 140),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1714).withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD7CCB9).withOpacity(0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pin.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF2EBDD),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pin.preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD7CCB9),
                  ),
                ),
                if (pin.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    pin.tags.join(' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD7CCB9),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '자세히 보기 ›',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xBFD7CCB9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          CustomPaint(
            size: const Size(10, 6),
            painter: _BubbleTailPainter(),
          ),
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1714).withOpacity(0.92)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PowerOffNotice extends StatelessWidget {
  const _PowerOffNotice({this.textStyle});

  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2B2620),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          '라디오의 전원이 켜지지 않았어요',
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );
  }
}

class _RadioLayout extends StatelessWidget {
  const _RadioLayout({
    required this.child,
    required this.tabViews,
    required this.indicatorLabel,
    required this.tabIndex,
    required this.indicatorLeftReserved,
    required this.indicatorLabelPadding,
    required this.enableIndicatorNudge,
    required this.needlePositionOverride,
    required this.needleColor,
    required this.showControls,
    required this.powerOn,
    required this.isLoggedIn,
    this.onPrev,
    this.onPower,
    this.onNext,
  });

  final Widget? child;
  final List<Widget>? tabViews;
  final String indicatorLabel;
  final int tabIndex;
  final double indicatorLeftReserved;
  final double indicatorLabelPadding;
  final bool enableIndicatorNudge;
  final double? needlePositionOverride;
  final Color? needleColor;
  final bool showControls;
  final bool powerOn;
  final bool isLoggedIn;
  final VoidCallback? onPrev;
  final VoidCallback? onPower;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: RadioTone.indicatorOuterHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: RadioTone.bezelBase,
              borderRadius: BorderRadius.circular(RadioTone.bezelRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(RadioTone.bezelInnerPadding),
              child: SizedBox(
                height: RadioTone.indicatorInnerHeight,
                child: RadioTopIndicator(
                  indicatorLabel: indicatorLabel,
                  tabIndex: tabIndex,
                  indicatorLeftReserved: indicatorLeftReserved,
                  indicatorLabelPadding: indicatorLabelPadding,
                  enableIndicatorNudge: enableIndicatorNudge,
                  needlePositionOverride: needlePositionOverride,
                  needleColor: needleColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: RadioTone.betweenIndicatorAndBezel),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: RadioTone.bezelBase,
                borderRadius: BorderRadius.circular(RadioTone.bezelRadius),
                border: Border.all(color: RadioTone.bezelEdge, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(RadioTone.bezelInnerPadding),
                child: Column(
                  children: [
                    Expanded(
                      child: RadioContentViewport(
                        child: child,
                        tabViews: tabViews,
                        tabIndex: tabIndex,
                        isPowerOn: powerOn,
                        isLoggedIn: isLoggedIn,
                      ),
                    ),
                    if (showControls) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        color: RadioTone.divider,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: RadioTone.controlsHeight,
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(RadioTone.controlsRadius),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/textures/wood_gain.jpg',
                                fit: BoxFit.cover,
                                color: const Color(0x33000000),
                                colorBlendMode: BlendMode.multiply,
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: RadioTone.controlsPadding,
                                  child: _ShellControls(
                                    onPrev: onPrev,
                                    onPower: onPower,
                                    onNext: onNext,
                                    powerOn: powerOn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RadioFrameBackground extends StatelessWidget {
  const RadioFrameBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/textures/wood_grain.png',
          fit: BoxFit.cover,
        ),
        const IgnorePointer(
          ignoring: true,
          child: ColoredBox(
            color: Color(0x14000000),
          ),
        ),
      ],
    );
  }
}

class RadioContentViewport extends StatelessWidget {
  const RadioContentViewport({
    super.key,
    this.child,
    this.tabViews,
    required this.tabIndex,
    required this.isPowerOn,
    required this.isLoggedIn,
  });

  final Widget? child;
  final List<Widget>? tabViews;
  final int tabIndex;
  final bool isPowerOn;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return SpeakerContentArea(
      isPowerOn: isPowerOn,
      isLoggedIn: isLoggedIn,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (child != null) {
      return child!;
    }
    final views = tabViews;
    if (views == null || views.isEmpty) {
      return const SizedBox.shrink();
    }
    final safeIndex = tabIndex < 0
        ? 0
        : (tabIndex >= views.length ? views.length - 1 : tabIndex);
    return IndexedStack(
      index: safeIndex,
      children: List<Widget>.generate(
        views.length,
        (index) => KeyedSubtree(
          key: PageStorageKey<String>('tab_$index'),
          child: views[index],
        ),
      ),
    );
  }
}

class RadioTopIndicator extends StatelessWidget {
  const RadioTopIndicator({
    super.key,
    required this.indicatorLabel,
    required this.tabIndex,
    required this.indicatorLeftReserved,
    required this.indicatorLabelPadding,
    required this.enableIndicatorNudge,
    required this.needlePositionOverride,
    required this.needleColor,
  });

  final String indicatorLabel;
  final int tabIndex;
  final double indicatorLeftReserved;
  final double indicatorLabelPadding;
  final bool enableIndicatorNudge;
  final double? needlePositionOverride;
  final Color? needleColor;

  @override
  Widget build(BuildContext context) {
    return RetroIndicatorBar(
      label: indicatorLabel,
      needlePosition:
          needlePositionOverride ?? _needlePositionForTab(tabIndex),
      leftSlotWidth: indicatorLeftReserved,
      rightSlotWidth: RadioTone.indicatorRightSlot,
      labelPaddingLeft: indicatorLabelPadding,
      labelPaddingRight: RadioTone.indicatorLabelPadRight,
      tickGap: RadioTone.indicatorTickGap,
      tickPaddingLeft: RadioTone.indicatorTickPadLeft,
      tabIndex: tabIndex,
      enableNudge: enableIndicatorNudge,
      needleColor: needleColor,
    );
  }

  double _needlePositionForTab(int index) {
    const positions = [0.12, 0.38, 0.64, 0.88];
    if (index < 0 || index >= positions.length) {
      return positions.first;
    }
    return positions[index];
  }
}

class _ShellControls extends StatelessWidget {
  const _ShellControls({
    required this.onPrev,
    required this.onPower,
    required this.onNext,
    required this.powerOn,
  });

  final VoidCallback? onPrev;
  final VoidCallback? onPower;
  final VoidCallback? onNext;
  final bool powerOn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _ControlButton(
              icon: Icons.chevron_left,
              size: RadioTone.controlSize,
              onTap: onPrev,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: _ControlButton(
              icon: Icons.power_settings_new,
              size: RadioTone.powerSize,
              onTap: onPower,
              isActive: powerOn,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _ControlButton(
              icon: Icons.chevron_right,
              size: RadioTone.controlSize,
              onTap: onNext,
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final double size;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isActive ? const Color(0xFFE53935) : RadioTone.controlIcon;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: onTap,
        radius: size / 1.6,
        highlightColor: Colors.white.withOpacity(0.06),
        containedInkWell: true,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                RadioTone.controlTop,
                RadioTone.controlBottom,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: RadioTone.controlStroke, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: size * 0.48,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
