import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';

class SpeakButtonCard extends ConsumerWidget {
  final VoidCallback onTap;

  const SpeakButtonCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryLight : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The large mic button
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.white : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : AppColors.primary).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.mic_none_rounded,
                      color: isDark ? AppColors.primary : AppColors.white,
                      size: 54,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Text
                if (isUrdu)
                  Text(
                    AppStrings.speakUrdu,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.primary,
                    ),
                  ),
                if (isUrdu) const SizedBox(height: 4),
                Text(
                  AppStrings.speak,
                  style: GoogleFonts.inter(
                    fontSize: isUrdu ? 12 : 24,
                    fontWeight: isUrdu ? FontWeight.w800 : FontWeight.w700,
                    color: isDark ? AppColors.white.withValues(alpha: 0.8) : AppColors.primary,
                    letterSpacing: isUrdu ? 1.5 : 0,
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
