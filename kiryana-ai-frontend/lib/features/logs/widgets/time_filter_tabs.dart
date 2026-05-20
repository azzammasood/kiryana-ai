import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';

class TimeFilterTabs extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const TimeFilterTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const List<Map<String, String>> _tabs = [
    {
      'urdu': AppStrings.todayUrdu,
      'english': AppStrings.todayEnglish,
    },
    {
      'urdu': AppStrings.thisWeekUrdu,
      'english': AppStrings.thisWeekEnglish,
    },
    {
      'urdu': AppStrings.thisMonthUrdu,
      'english': AppStrings.thisMonthEnglish,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = selectedIndex == index;
            final tab = _tabs[index];
            final label = isUrdu ? tab['urdu']! : tab['english']!.replaceAll('(', '').replaceAll(')', '');

            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkCard : AppColors.white),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                    border: isSelected
                        ? (isDark ? Border.all(color: AppColors.white.withValues(alpha: 0.5), width: 1) : null)
                        : Border.all(color: (isDark ? AppColors.darkBorder : AppColors.primary).withValues(alpha: 0.55)),
                  ),
                  child: Text(
                    label,
                    textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                    style: isUrdu
                        ? TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          )
                        : GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.white
                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

