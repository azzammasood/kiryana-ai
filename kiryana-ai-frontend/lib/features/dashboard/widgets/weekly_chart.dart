import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import 'package:kiryana_ai/features/logs/providers/transaction_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../../core/widgets/app_widgets.dart';

class WeeklyChart extends ConsumerWidget {
  const WeeklyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartData = ref.watch(weeklyChartDataProvider);
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.white;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.14) : AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.55)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header - Fixed position (English left, Urdu right)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: isUrdu ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: primaryTextColor.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUrdu ? AppStrings.weeklyOverviewUrdu : AppStrings.weeklyOverview,
                      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
          Divider(color: (isDark ? AppColors.darkBorder : AppColors.primary).withValues(alpha: 0.35)),
          const SizedBox(height: AppSpacing.md),

          // Chart - Forced LTR to keep day order fixed
          SizedBox(
            height: 160,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: _buildBars(context, chartData, isDark, secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBars(BuildContext context, List<DayChartData> data, bool isDark, Color secondaryTextColor) {
    // Find max absolute net value for proportional scaling
    final maxVal = data.map((e) => e.net.abs()).fold(0, (a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(data.length, (index) {
        final day = data[index];
        final netVal = day.net;
        final isPositive = netVal > 0;
        final isEmpty = netVal == 0;

        // Calculate relative height
        double heightFactor = maxVal == 0 ? 0 : (netVal.abs() / maxVal);
        if (!isEmpty && heightFactor < 0.1) heightFactor = 0.1;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              AppToast.show(
                context,
                '${day.label}: Income Rs ${day.income} | Expense Rs ${day.expense} | Net Rs ${day.net}',
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Amount label above bar
                if (!isEmpty)
                  Text(
                    _formatAmount(netVal.abs()),
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: isPositive
                          ? (isDark ? AppColors.white : AppColors.actionGreen)
                          : (isDark ? AppColors.errorReadable : AppColors.error),
                    ),
                  ),
                if (!isEmpty) const SizedBox(height: 2),

                // Bar
                Container(
                  width: 24,
                  height: isEmpty ? 8 : (100 * heightFactor),
                  decoration: BoxDecoration(
                    color: isEmpty
                        ? AppColors.textSecondary.withValues(alpha: 0.2)
                        : (isPositive
                            ? const Color(0xFF1B6D24)
                            : (isDark ? AppColors.errorReadable : AppColors.error)),
                    borderRadius: BorderRadius.circular(6),
                    border: day.isToday
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                // Day Label
                Text(
                  day.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
                    color: day.isToday
                        ? (isDark ? AppColors.white : AppColors.primary)
                        : secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toString();
  }
}
