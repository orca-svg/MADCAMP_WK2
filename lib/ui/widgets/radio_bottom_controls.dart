import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RadioBottomControls extends StatelessWidget {
  const RadioBottomControls({
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _PressableCircleButton(
          icon: Icons.chevron_left,
          size: 64,
          onPressed: onPrev,
          tooltip: 'Previous',
        ),
        _PowerCircleButton(
          icon: Icons.power_settings_new,
          size: 74,
          onPressed: onPower,
          tooltip: 'Power',
          isActive: powerOn,
        ),
        _PressableCircleButton(
          icon: Icons.chevron_right,
          size: 64,
          onPressed: onNext,
          tooltip: 'Next',
        ),
      ],
    );
  }
}

class _PressableCircleButton extends StatefulWidget {
  const _PressableCircleButton({
    required this.icon,
    required this.size,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final double size;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  State<_PressableCircleButton> createState() => _PressableCircleButtonState();
}

class _PressableCircleButtonState extends State<_PressableCircleButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final scale = _pressed ? 0.94 : 1.0;
    final blur = _pressed ? 6.0 : 16.0;

    return Tooltip(
      message: widget.tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkResponse(
            onTap: enabled ? widget.onPressed : null,
            onTapDown: enabled
                ? (_) {
                    HapticFeedback.lightImpact();
                    _setPressed(true);
                  }
                : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            onTapUp: enabled ? (_) => _setPressed(false) : null,
            highlightColor: Colors.white.withOpacity(0.06),
            splashFactory: InkSparkle.splashFactory,
            containedInkWell: true,
            customBorder: const CircleBorder(),
            child: AnimatedScale(
              scale: scale,
              duration: Duration(milliseconds: _pressed ? 90 : 140),
              child: AnimatedContainer(
                duration: Duration(milliseconds: _pressed ? 90 : 140),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD7D7D7), Color(0xFFBEBEBE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/textures/brushed_metal.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color(0x2EFFFFFF),
                      BlendMode.softLight,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x66000000),
                      blurRadius: blur,
                      offset: const Offset(0, 6),
                    ),
                    const BoxShadow(
                      color: Color(0x22FFFFFF),
                      blurRadius: 6,
                      offset: Offset(0, -2),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0x66FFFFFF),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: const Color(0xFF2B2B2B),
                    size: widget.size * 0.48,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerCircleButton extends StatefulWidget {
  const _PowerCircleButton({
    required this.icon,
    required this.size,
    required this.onPressed,
    required this.tooltip,
    required this.isActive,
  });

  final IconData icon;
  final double size;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isActive;

  @override
  State<_PowerCircleButton> createState() => _PowerCircleButtonState();
}

class _PowerCircleButtonState extends State<_PowerCircleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.06),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(covariant _PowerCircleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
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
    final enabled = widget.onPressed != null;
    final iconColor =
        widget.isActive ? const Color(0xFFE53935) : const Color(0xFF2B2B2B);

    return Tooltip(
      message: widget.tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkResponse(
            onTap: enabled ? widget.onPressed : null,
            onTapDown: enabled
                ? (_) {
                    HapticFeedback.mediumImpact();
                  }
                : null,
            highlightColor: Colors.white.withOpacity(0.06),
            splashFactory: InkSparkle.splashFactory,
            containedInkWell: true,
            customBorder: const CircleBorder(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: widget.size + (widget.isActive ? 18 : 0),
                  height: widget.size + (widget.isActive ? 18 : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: widget.isActive
                        ? const [
                            BoxShadow(
                              color: Color(0x8CE53935),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ]
                        : const [],
                  ),
                ),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD7D7D7), Color(0xFFBEBEBE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
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
                          color: Color(0x66000000),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Color(0x22FFFFFF),
                          blurRadius: 6,
                          offset: Offset(0, -2),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0x66FFFFFF),
                        width: 1.2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (widget.isActive)
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: true,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0x33E53935),
                                ),
                              ),
                            ),
                          ),
                        Center(
                          child: Icon(
                            widget.icon,
                            color: iconColor,
                            size: widget.size * 0.48,
                          ),
                        ),
                      ],
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
