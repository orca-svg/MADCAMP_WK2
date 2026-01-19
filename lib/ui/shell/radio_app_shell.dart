import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/radio_tone.dart';
import '../widgets/retro_indicator_bar.dart';
import '../widgets/speaker_content_area.dart';

class RadioAppShell extends StatefulWidget {
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
  State<RadioAppShell> createState() => _RadioAppShellState();
}

class _RadioAppShellState extends State<RadioAppShell> {
  DateTime? _lastPowerOffSnackAt;
  bool _powerOffNoticeVisible = false;
  Timer? _noticeTimer;

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
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
