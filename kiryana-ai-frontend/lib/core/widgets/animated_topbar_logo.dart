import 'package:flutter/material.dart';

/// Subtle pulse on the existing topbar logo asset (no image file changes).
class AnimatedTopBarLogo extends StatefulWidget {
  final double size;

  const AnimatedTopBarLogo({super.key, this.size = 32});

  @override
  State<AnimatedTopBarLogo> createState() => _AnimatedTopBarLogoState();
}

class _AnimatedTopBarLogoState extends State<AnimatedTopBarLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
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
      builder: (context, child) {
        final t = _controller.value;
        final scale = 0.94 + (0.06 * t);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: 0.88 + (0.12 * t),
            child: child,
          ),
        );
      },
      child: Image.asset(
        'assets/images/topbar-logo.png',
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
