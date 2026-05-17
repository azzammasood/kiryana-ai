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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                      color: AppColors.primary.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.weeklyOverview,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (isUrdu)
                  const Text(
                    AppStrings.weeklyOverviewUrdu,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
          Divider(color: AppColors.primary.withValues(alpha: 0.1)),
          const SizedBox(height: AppSpacing.md),

          // Chart - Forced LTR to keep day order fixed
          SizedBox(
            height: 160,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: _buildBars(context, chartData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBars(BuildContext context, List<DayChartData> data) {
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
                          ? const Color(0xFF1B6D24)
                          : const Color(0xFFD32F2F),
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
                            : const Color(0xFFD32F2F)),
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
                        ? AppColors.primary
                        : AppColors.textSecondary,
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
