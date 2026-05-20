import 'package:flutter/material.dart';

/// Animated Gemini-style sparkle used on voice / Ask AI screens.
class GeminiSparkleIndicator extends StatefulWidget {
  final double size;

  const GeminiSparkleIndicator({super.key, this.size = 150});

  @override
  State<GeminiSparkleIndicator> createState() => _GeminiSparkleIndicatorState();
}

class _GeminiSparkleIndicatorState extends State<GeminiSparkleIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.size / 150;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final pulse = 0.96 + (0.08 * (0.5 - (t - 0.5).abs()) * 2);
        return Transform.scale(
          scale: pulse,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 136 * scale,
                  height: 136 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7DD3FC).withValues(alpha: 0.20),
                        blurRadius: 34 * scale,
                        spreadRadius: 8 * scale,
                      ),
                    ],
                  ),
                ),
                Transform.rotate(
                  angle: t * 6.28318530718,
                  child: Container(
                    width: 118 * scale,
                    height: 118 * scale,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0x004F46E5),
                          Color(0xFF4F46E5),
                          Color(0xFF7DD3FC),
                          Color(0x004F46E5),
                        ],
                        stops: [0.00, 0.45, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 96 * scale,
                  height: 96 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3645).withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7DD3FC).withValues(alpha: 0.22),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -(t * 6.28318530718),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 44 * scale,
                    color: const Color(0xFFB6ECFF),
                  ),
                ),
                ...List.generate(4, (index) {
                  final angle = (index * 1.57079632679) + (t * 6.28318530718);
                  final x = 47 * scale * (index.isEven ? 1 : -1);
                  final y = 47 * scale * (index < 2 ? 1 : -1);
                  return Transform.rotate(
                    angle: angle,
                    child: Transform.translate(
                      offset: Offset(x, y),
                      child: Container(
                        width: (index.isEven ? 9 : 7) * scale,
                        height: (index.isEven ? 9 : 7) * scale,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7DD3FC),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact Gemini-style icon for list tiles (learning badge, etc.).
class GeminiTileIcon extends StatelessWidget {
  final double size;

  const GeminiTileIcon({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF5B4BDB), Color(0xFF3D7DD6), Color(0xFFE0569B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7DD3FC).withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
