import 'package:flutter/material.dart';

import 'radio_tone.dart';
import 'retro_indicator_bar.dart';
import 'speaker_content_area.dart';

class RadioShell extends StatelessWidget {
  const RadioShell({
    super.key,
    required this.child,
    required this.indicatorLabel,
    this.tabIndex = 0,
    this.isLoginMode = false,
    this.isPowerOn = false,
    this.isLoggedIn = true,
    this.onPrev,
    this.onPower,
    this.onNext,
  });

  final Widget child;
  final String indicatorLabel;
  final int tabIndex;
  final bool isLoginMode;
  final bool isPowerOn;
  final bool isLoggedIn;
  final VoidCallback? onPrev;
  final VoidCallback? onPower;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final bodyHeight = maxHeight < 760 ? maxHeight : 760.0;
            final bodyWidth =
                constraints.maxWidth < 520 ? constraints.maxWidth : 520.0;
            return Stack(
              children: [
                Positioned.fill(child: _BackgroundLayer()),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: bodyWidth,
                    height: bodyHeight.toDouble(),
                    child: Container(
                      margin: EdgeInsets.zero,
                      // Align indicator and bezel widths with a single padding system.
                      padding: RadioTone.shellPadding,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(RadioTone.shellOuterRadius),
                        image: const DecorationImage(
                          image: AssetImage('assets/textures/wood_grain.png'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            RadioTone.woodOverlayDark,
                            BlendMode.multiply,
                          ),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: RadioTone.woodShadow,
                            blurRadius: 24,
                            offset: Offset(0, 14),
                          ),
                        ],
                        border: Border.all(
                          color: RadioTone.woodOverlayDark,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: RadioTone.indicatorOuterHeight,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: RadioTone.bezelBase,
                                borderRadius:
                                    BorderRadius.circular(RadioTone.bezelRadius),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(RadioTone.bezelInnerPadding),
                                child: SizedBox(
                                  height: RadioTone.indicatorInnerHeight,
                                  child: RetroIndicatorBar(
                                    label: indicatorLabel,
                                    needlePosition: isLoginMode
                                        ? 0.0
                                        : _needlePositionForTab(tabIndex),
                                    needleColor: isLoginMode ? Colors.grey : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: RadioTone.betweenIndicatorAndBezel),
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: RadioTone.bezelBase,
                                borderRadius:
                                    BorderRadius.circular(RadioTone.bezelRadius),
                                border: Border.all(
                                  color: RadioTone.bezelEdge,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  RadioTone.bezelInnerPadding,
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: SpeakerContentArea(
                                        child: child,
                                        isPowerOn: isPowerOn,
                                        isLoggedIn: isLoggedIn,
                                      ),
                                    ),
                                    if (!isLoginMode) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 2,
                                        color: RadioTone.divider,
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: RadioTone.controlsHeight,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            RadioTone.controlsRadius,
                                          ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              // wood_gain.jpg + multiply overlay for deeper tone.
                                              Image.asset(
                                                'assets/textures/wood_gain.jpg',
                                                fit: BoxFit.cover,
                                                color: const Color(0x33000000),
                                                colorBlendMode: BlendMode.multiply,
                                              ),
                                              Align(
                                                alignment: Alignment.center,
                                                child: Padding(
                                                  padding:
                                                      RadioTone.controlsPadding,
                                                  child: _ShellControls(
                                                    onPrev: onPrev,
                                                    onPower: onPower,
                                                    onNext: onNext,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
  });

  final VoidCallback? onPrev;
  final VoidCallback? onPower;
  final VoidCallback? onNext;

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
  });

  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
            color: RadioTone.controlIcon,
          ),
        ),
      ),
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
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
