import 'package:flutter/material.dart';

import 'radio_tone.dart';

class SpeakerContentArea extends StatelessWidget {
  const SpeakerContentArea({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = RadioTone.contentRadius;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: RadioTone.contentSurfaceBottom,
          gradient: const LinearGradient(
            colors: [
              RadioTone.contentSurfaceTop,
              RadioTone.contentSurfaceBottom,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0x33000000),
                    BlendMode.multiply,
                  ),
                  child: Image.asset(
                    'assets/textures/fabric_grille.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(0x14000000),
                        Color(0x99000000),
                      ],
                      center: Alignment(0.0, -0.1),
                      radius: 0.9,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: const Color(0x2ED7CCB9),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
