import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'dart:math' as math;

class AudioWaveform extends StatefulWidget {
  final bool isListening;

  const AudioWaveform({
    super.key,
    this.isListening = true,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Constants for waveform
  final int _barCount = 13;
  final double _maxHeight = 80.0;
  final double _minHeight = 10.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void didUpdateWidget(AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _controller.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _controller.stop();
      // Optional: animate to 0 or minimum height smoothly
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_barCount, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Create a staggered wave effect based on the index
              final t = _controller.value;
              final phase = (index / _barCount) * math.pi * 2;
              
              // Base sine wave
              double wave = math.sin((t * math.pi * 4) + phase);
              
              // Normalize from [-1, 1] to [0, 1]
              wave = (wave + 1) / 2;
              
              // If not listening, make height very small
              final height = widget.isListening 
                  ? _minHeight + (wave * (_maxHeight - _minHeight))
                  : _minHeight;

              // Color gradient: Center bars are darker green, outer bars are lighter/greyish teal
              final distanceFromCenter = (index - (_barCount ~/ 2)).abs();
              final isCenter = distanceFromCenter <= 2;
              
              final isDark = Theme.of(context).brightness == Brightness.dark;
              
              final Color color;
              if (isDark) {
                color = isCenter 
                    ? AppColors.white 
                    : AppColors.white.withValues(alpha: 0.6 - (distanceFromCenter * 0.1));
              } else {
                color = isCenter 
                    ? AppColors.actionGreen 
                    : AppColors.primary.withValues(alpha: 0.5 - (distanceFromCenter * 0.05));
              }

              return Container(
                width: 6,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
