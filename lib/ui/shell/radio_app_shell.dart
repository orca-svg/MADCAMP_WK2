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
    this.indicatorLeftReserved = 86,
    this.indicatorLabelPadding = 14,
    this.enableIndicatorNudge = true,
    this.needlePositionOverride,
    this.needleColor,
    this.showControls = true,
    this.powerOn = false,
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
  final VoidCallback? onPrev;
  final VoidCallback? onPower;
  final VoidCallback? onNext;

  @override
  State<RadioAppShell> createState() => _RadioAppShellState();
}

class _RadioAppShellState extends State<RadioAppShell> {
  DateTime? _lastPowerOffSnackAt;

  bool _canShowPowerOffSnack() {
    final last =
        _lastPowerOffSnackAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.now().difference(last).inMilliseconds >= 2500;
  }

  void _showPowerOffSnack(BuildContext context) {
    if (!_canShowPowerOffSnack()) return; // 2.5s throttle.
    _lastPowerOffSnackAt = DateTime.now();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar(); // Avoid stacking off-screen snackbars.
    messenger.showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.fixed, // Off-screen 방지.
        duration: Duration(milliseconds: 1800),
        content: Text(
          '라디오의 전원이 켜지지 않았어요',
          textAlign: TextAlign.center,
        ),
      ),
    );
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
  final VoidCallback? onPrev;
  final VoidCallback? onPower;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioTopIndicator(
          indicatorLabel: indicatorLabel,
          tabIndex: tabIndex,
          indicatorLeftReserved: indicatorLeftReserved,
          indicatorLabelPadding: indicatorLabelPadding,
          enableIndicatorNudge: enableIndicatorNudge,
          needlePositionOverride: needlePositionOverride,
          needleColor: needleColor,
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
          color: RadioTone.woodOverlayDark,
          colorBlendMode: BlendMode.multiply,
        ),
        IgnorePointer(
          ignoring: true,
          child: Image.asset(
            'assets/textures/noise.png',
            fit: BoxFit.cover,
            color: const Color(0x0FFFFFFF),
            colorBlendMode: BlendMode.modulate,
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
  });

  final Widget? child;
  final List<Widget>? tabViews;
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    return SpeakerContentArea(
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
      leftReserved: indicatorLeftReserved,
      labelPadding: indicatorLabelPadding,
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.chevron_left,
          size: RadioTone.controlSize,
          onTap: onPrev,
        ),
        const SizedBox(width: RadioTone.controlGap),
        _ControlButton(
          icon: Icons.power_settings_new,
          size: RadioTone.powerSize,
          onTap: onPower,
          isActive: powerOn,
        ),
        const SizedBox(width: RadioTone.controlGap),
        _ControlButton(
          icon: Icons.chevron_right,
          size: RadioTone.controlSize,
          onTap: onNext,
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
