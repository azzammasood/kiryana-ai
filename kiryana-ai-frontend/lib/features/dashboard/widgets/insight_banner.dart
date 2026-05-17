import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../data/mock/mock_dashboard_data.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';

class InsightBanner extends ConsumerWidget {
  final String? urduText;
  final String? englishText;

  const InsightBanner({
    super.key,
    this.urduText,
    this.englishText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            Color(0xFF007575), // A slightly lighter teal
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.white,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isUrdu)
                  Text(
                    urduText ?? DashboardMockData.currentInsightUrdu,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      height: 1.4,
                    ),
                  ),
                if (isUrdu) const SizedBox(height: 4),
                Text(
                  englishText ?? DashboardMockData.currentInsightEnglish,
                  style: GoogleFonts.inter(
                    fontSize: isUrdu ? 11 : 14,
                    fontWeight: isUrdu ? FontWeight.w500 : FontWeight.w700,
                    color: isUrdu ? AppColors.white.withValues(alpha: 0.8) : AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
