import 'package:flutter/material.dart';

/// Pulsing glow animation for learning screens (no rotation).
class AnimatedBulbIndicator extends StatefulWidget {
  final double size;

  const AnimatedBulbIndicator({super.key, this.size = 48});

  @override
  State<AnimatedBulbIndicator> createState() => _AnimatedBulbIndicatorState();
}

class _AnimatedBulbIndicatorState extends State<AnimatedBulbIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
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
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final glow = 0.25 + (t * 0.45);
        final scale = 0.94 + (t * 0.08);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.35),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: glow),
                  blurRadius: 18 + (t * 10),
                  spreadRadius: 2 + (t * 4),
                ),
                BoxShadow(
                  color: const Color(0xFFFFF59D).withValues(alpha: glow * 0.7),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              size: widget.size * 0.62,
              color: Color.lerp(
                const Color(0xFF5D4037),
                const Color(0xFFE65100),
                t,
              ),
            ),
          ),
        );
      },
    );
  }
}
