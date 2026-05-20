import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// Full-screen blurred overlay while a log or form is persisting.
class SavingOverlay extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SavingOverlay({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xl,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
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
