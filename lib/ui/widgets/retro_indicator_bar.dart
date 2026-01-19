import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'radio_tone.dart';

class RetroIndicatorBar extends StatefulWidget {
  const RetroIndicatorBar({
    super.key,
    required this.label,
    required this.needlePosition,
    this.needleColor,
    this.leftSlotWidth = RadioTone.indicatorLeftSlot,
    this.rightSlotWidth = RadioTone.indicatorRightSlot,
    this.labelPaddingLeft = RadioTone.indicatorLabelPadLeft,
    this.labelPaddingRight = RadioTone.indicatorLabelPadRight,
    this.tickGap = RadioTone.indicatorTickGap,
    this.tickPaddingLeft = RadioTone.indicatorTickPadLeft,
    this.tabIndex = 0,
    this.enableNudge = true,
  });

  final String label;
  final double needlePosition;
  final Color? needleColor;
  final double leftSlotWidth;
  final double rightSlotWidth;
  final double labelPaddingLeft;
  final double labelPaddingRight;
  final double tickGap;
  final double tickPaddingLeft;
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
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFBFBFBF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                tween: Tween<double>(end: widget.needlePosition.clamp(0.0, 1.0)),
                builder: (context, value, _) {
                  final leftReserved =
                      widget.leftSlotWidth + widget.tickGap + widget.tickPaddingLeft;
                  return CustomPaint(
                    painter: _IndicatorPainter(
                      value,
                      leftReserved: leftReserved,
                      rightReserved: widget.rightSlotWidth,
                      needleColor: widget.needleColor,
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: widget.leftSlotWidth,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: widget.labelPaddingLeft,
                        right: widget.labelPaddingRight,
                      ),
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: Color(0xA6000000),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: widget.tickGap),
                const Expanded(child: SizedBox()),
                SizedBox(width: widget.rightSlotWidth),
              ],
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
    Color? needleColor,
  }) : needleColor = needleColor ?? const Color(0xFFE3392B);

  final double needlePosition;
  final double leftReserved;
  final double rightReserved;
  final Color needleColor;

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
      ..color = needleColor.withOpacity(0.45)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final needlePaint = Paint()
      ..color = needleColor
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
      Paint()..color = needleColor,
    );
  }

  @override
  bool shouldRepaint(covariant _IndicatorPainter oldDelegate) {
    return oldDelegate.needlePosition != needlePosition ||
        oldDelegate.leftReserved != leftReserved ||
        oldDelegate.rightReserved != rightReserved ||
        oldDelegate.needleColor != needleColor;
  }
}
