import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/latest_insight_provider.dart';

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

    if (isUrdu && urduText != null) {
      return _bannerBody(isUrdu, urduText!);
    }
    if (!isUrdu && englishText != null) {
      return _bannerBody(isUrdu, englishText!);
    }

    final insightState = ref.watch(latestInsightProvider);
    final live = (insightState.data?['key_insight'] ?? '').toString().trim();
    final fallback = isUrdu
        ? (insightState.showFullScreenLoader
            ? 'AI مشورہ لوڈ ہو رہا ہے...'
            : 'رپورٹ بنانے کے بعد AI مشورہ یہاں آئے گا۔')
        : (insightState.showFullScreenLoader
            ? 'Loading live AI advice...'
            : 'Generate a report to see live AI advice here.');
    final text = live.isEmpty ? fallback : live;

    return _bannerBody(isUrdu, text);
  }

  Widget _bannerBody(bool isUrdu, String text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.aiPurple,
            AppColors.aiBlue,
            AppColors.aiPink,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.aiPurple.withValues(alpha: 0.24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              style: isUrdu
                  ? const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      height: 1.4,
                    )
                  : GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
