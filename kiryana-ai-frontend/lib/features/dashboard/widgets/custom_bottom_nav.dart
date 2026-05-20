import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';

class CustomBottomNav extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: isDark
            ? Border(top: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.65)))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.18) : AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Directionality(
            textDirection: TextDirection.ltr, // Keep order fixed like English
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  titleUrdu: AppStrings.navHomeUrdu,
                  titleEnglish: AppStrings.navHome,
                  isActive: currentIndex == 0,
                  isUrdu: isUrdu,
                  isDark: isDark,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  titleUrdu: AppStrings.navLogsUrdu,
                  titleEnglish: AppStrings.navLogs,
                  isActive: currentIndex == 1,
                  isUrdu: isUrdu,
                  isDark: isDark,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  icon: Icons.insights_rounded,
                  titleUrdu: AppStrings.navInsightsUrdu,
                  titleEnglish: AppStrings.navInsights,
                  isActive: currentIndex == 2,
                  isUrdu: isUrdu,
                  isDark: isDark,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  titleUrdu: AppStrings.navSettingsUrdu,
                  titleEnglish: AppStrings.navSettings,
                  isActive: currentIndex == 3,
                  isUrdu: isUrdu,
                  isDark: isDark,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String titleUrdu;
  final String titleEnglish;
  final bool isActive;
  final bool isUrdu;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.titleUrdu,
    required this.titleEnglish,
    required this.isActive,
    required this.isUrdu,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.primaryLight.withValues(alpha: 0.85) : const Color(0xFFE0F2F1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? (isDark ? AppColors.white : AppColors.primary)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              size: 24,
            ),
            const SizedBox(height: 4),
            if (isUrdu)
              Text(
                titleUrdu,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? (isDark ? AppColors.white : AppColors.primary)
                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ),
            if (!isUrdu)
              Text(
                titleEnglish,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? (isDark ? AppColors.white : AppColors.primary)
                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
