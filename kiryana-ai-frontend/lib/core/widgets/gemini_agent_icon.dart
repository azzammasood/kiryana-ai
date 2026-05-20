import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Gradient sparkle icon used for Gemini / AI agent surfaces.
class GeminiAgentIcon extends StatelessWidget {
  final double size;
  final double iconSize;

  const GeminiAgentIcon({
    super.key,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.aiPurple,
            AppColors.aiBlue,
            AppColors.aiPink,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: AppColors.white,
        size: iconSize,
      ),
    );
  }
}
