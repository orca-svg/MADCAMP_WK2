import 'package:flutter/material.dart';

import 'radio_bottom_controls.dart';
import 'retro_indicator_bar.dart';
import 'speaker_content_area.dart';

class RadioShell extends StatelessWidget {
  const RadioShell({
    super.key,
    required this.child,
    required this.indicatorLabel,
    this.tabIndex = 0,
    this.onPrev,
    this.onPower,
    this.onNext,
  });

  final Widget child;
  final String indicatorLabel;
  final int tabIndex;
  final VoidCallback? onPrev;
  final VoidCallback? onPower;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        image: const DecorationImage(
                          image: AssetImage('assets/textures/wood_grain.jpg'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Color(0xFF3C2616),
                            BlendMode.overlay,
                          ),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x88000000),
                            blurRadius: 24,
                            offset: Offset(0, 14),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0x6626150C),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          RetroIndicatorBar(
                            label: indicatorLabel,
                            needlePosition: _needlePositionForTab(tabIndex),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: SpeakerContentArea(child: child),
                          ),
                          const SizedBox(height: 14),
                          RadioBottomControls(
                            onPrev: onPrev,
                            onPower: onPower,
                            onNext: onNext,
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

class _BackgroundLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF1B120A), Color(0xFF0D0A07)],
          radius: 1.1,
          center: Alignment(0.0, -0.2),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/textures/noise.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/textures/dust.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
