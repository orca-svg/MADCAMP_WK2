import 'package:flutter/material.dart';

import '../widgets/radio_bottom_controls.dart';
import '../widgets/retro_indicator_bar.dart';
import '../widgets/speaker_content_area.dart';

class RadioAppShell extends StatelessWidget {
  const RadioAppShell({
    super.key,
    required this.child,
    required this.indicatorLabel,
    this.tabIndex = 0,
    this.indicatorLeftReserved = 86,
    this.indicatorLabelPadding = 14,
    this.enableIndicatorNudge = true,
    this.needlePositionOverride,
    this.showControls = true,
    this.powerOn = false,
    this.onPrev,
    this.onPower,
    this.onNext,
  });

  final Widget child;
  final String indicatorLabel;
  final int tabIndex;
  final double indicatorLeftReserved;
  final double indicatorLabelPadding;
  final bool enableIndicatorNudge;
  final double? needlePositionOverride;
  final bool showControls;
  final bool powerOn;
  final VoidCallback? onPrev;
  final VoidCallback? onPower;
  final VoidCallback? onNext;

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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: _RadioLayout(
                indicatorLabel: indicatorLabel,
                tabIndex: tabIndex,
                indicatorLeftReserved: indicatorLeftReserved,
                indicatorLabelPadding: indicatorLabelPadding,
                enableIndicatorNudge: enableIndicatorNudge,
                needlePositionOverride: needlePositionOverride,
                showControls: showControls,
                powerOn: powerOn,
                onPrev: onPrev,
                onPower: onPower,
                onNext: onNext,
                child: child,
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
    required this.indicatorLabel,
    required this.tabIndex,
    required this.indicatorLeftReserved,
    required this.indicatorLabelPadding,
    required this.enableIndicatorNudge,
    required this.needlePositionOverride,
    required this.showControls,
    required this.powerOn,
    this.onPrev,
    this.onPower,
    this.onNext,
  });

  final Widget child;
  final String indicatorLabel;
  final int tabIndex;
  final double indicatorLeftReserved;
  final double indicatorLabelPadding;
  final bool enableIndicatorNudge;
  final double? needlePositionOverride;
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
        ),
        const SizedBox(height: 14),
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: RadioContentViewport(child: child),
          ),
        ),
        const SizedBox(height: 14),
        if (showControls)
          SizedBox(
            height: 92,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RadioBottomNav(
                onPrev: onPrev,
                onPower: onPower,
                onNext: onNext,
                powerOn: powerOn,
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
          'assets/textures/wood_grain.jpg',
          fit: BoxFit.cover,
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
  });

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: SpeakerContentArea(
        child: child ?? const SizedBox.shrink(),
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
  });

  final String indicatorLabel;
  final int tabIndex;
  final double indicatorLeftReserved;
  final double indicatorLabelPadding;
  final bool enableIndicatorNudge;
  final double? needlePositionOverride;

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

class RadioBottomNav extends StatelessWidget {
  const RadioBottomNav({
    super.key,
    this.onPrev,
    this.onPower,
    this.onNext,
    this.powerOn = false,
  });

  final VoidCallback? onPrev;
  final VoidCallback? onPower;
  final VoidCallback? onNext;
  final bool powerOn;

  @override
  Widget build(BuildContext context) {
    return RadioBottomControls(
      onPrev: onPrev,
      onPower: onPower,
      onNext: onNext,
      powerOn: powerOn,
    );
  }
}
