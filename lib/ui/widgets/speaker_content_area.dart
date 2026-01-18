import 'package:flutter/material.dart';

class SpeakerContentArea extends StatelessWidget {
  const SpeakerContentArea({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xB8141210),
          border: Border.all(
            color: const Color(0x38C9A24C),
            width: 1.2,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Transform.scale(
                  scale: 0.9,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Color(0x2EFFFFFF),
                      BlendMode.srcATop,
                    ),
                    child: Image.asset(
                      'assets/textures/fabric_grille.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xB8141210),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C2724), Color(0xFF241F1C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: true,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0x0FFFFFFF), Color(0x00FFFFFF)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
