import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RetroIndicatorBar extends StatefulWidget {
  const RetroIndicatorBar({
    super.key,
    required this.label,
    required this.needlePosition,
    this.leftReserved = 86,
    this.labelPadding = 14,
    this.tabIndex = 0,
    this.enableNudge = true,
  });

  final String label;
  final double needlePosition;
  final double leftReserved;
  final double labelPadding;
  final int tabIndex;
  final bool enableNudge;

  @override
  State<RetroIndicatorBar> createState() => _RetroIndicatorBarState();
}

class _RetroIndicatorBarState extends State<RetroIndicatorBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _nudge;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _nudge = const AlwaysStoppedAnimation(0);
  }

  @override
  void didUpdateWidget(covariant RetroIndicatorBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableNudge && widget.tabIndex != oldWidget.tabIndex) {
      final direction = widget.tabIndex > oldWidget.tabIndex ? 1.0 : -1.0;
      _nudge = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 0.015 * direction)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.015 * direction, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 1,
        ),
      ]).animate(_controller);
      HapticFeedback.lightImpact();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FractionalTranslation(
          translation: Offset(_nudge.value, 0),
          child: child,
        );
      },
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE5E5E5),
              Color(0xFFBEBEBE),
              Color(0xFFEDEDED),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          image: const DecorationImage(
            image: AssetImage('assets/textures/brushed_metal.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0x2EFFFFFF),
              BlendMode.softLight,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                tween: Tween<double>(end: widget.needlePosition.clamp(0.0, 1.0)),
                builder: (context, value, _) {
                  return CustomPaint(
                    painter: _IndicatorPainter(
                      value,
                      leftReserved: widget.leftReserved,
                      rightReserved: 0,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: widget.leftReserved,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: widget.labelPadding),
                    child: Text(
                      widget.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xA6000000),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorPainter extends CustomPainter {
  _IndicatorPainter(
    this.needlePosition, {
    required this.leftReserved,
    required this.rightReserved,
  });

  final double needlePosition;
  final double leftReserved;
  final double rightReserved;

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = const Color(0x59000000)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const tickCount = 18;
    final startX = leftReserved;
    final endX = size.width - rightReserved;
    final tickAreaWidth = endX - startX;

    for (int i = 0; i < tickCount; i++) {
      final x = startX + tickAreaWidth * (i / (tickCount - 1));
      final yStart = size.height * 0.38;
      final yEnd = size.height * 0.76;
      canvas.drawLine(
        Offset(x, yStart),
        Offset(x, yEnd),
        tickPaint,
      );
    }

    final needleX = startX + tickAreaWidth * needlePosition;
    final glowPaint = Paint()
      ..color = const Color(0x73E3392B)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final needlePaint = Paint()
      ..color = const Color(0xFFE3392B)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(needleX, size.height * 0.22),
      Offset(needleX, size.height * 0.86),
      glowPaint,
    );
    canvas.drawLine(
      Offset(needleX, size.height * 0.22),
      Offset(needleX, size.height * 0.86),
      needlePaint,
    );

    canvas.drawCircle(
      Offset(needleX, size.height * 0.2),
      2.6,
      Paint()..color = const Color(0xFFE3392B),
    );
  }

  @override
  bool shouldRepaint(covariant _IndicatorPainter oldDelegate) {
    return oldDelegate.needlePosition != needlePosition ||
        oldDelegate.leftReserved != leftReserved ||
        oldDelegate.rightReserved != rightReserved;
  }
}
