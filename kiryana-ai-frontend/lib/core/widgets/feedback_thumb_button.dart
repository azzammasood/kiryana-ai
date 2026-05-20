import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Thumbs up/down with a quick scale bounce on tap.
class FeedbackThumbButton extends StatefulWidget {
  final bool isUp;
  final bool isSelected;
  final VoidCallback onTap;

  const FeedbackThumbButton({
    super.key,
    required this.isUp,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<FeedbackThumbButton> createState() => _FeedbackThumbButtonState();
}

class _FeedbackThumbButtonState extends State<FeedbackThumbButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.38), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.38, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final inactive = AppColors.textSecondary;
    final active = widget.isUp ? AppColors.actionGreen : AppColors.errorReadable;
    final color = widget.isSelected ? active : inactive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: ScaleTransition(
            scale: _scale,
            child: Icon(
              widget.isUp
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_down_alt_rounded,
              size: 28,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
