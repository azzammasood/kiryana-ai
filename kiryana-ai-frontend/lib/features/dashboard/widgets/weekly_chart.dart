import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import 'package:kiryana_ai/features/logs/providers/transaction_provider.dart';
import '../../../core/providers/language_provider.dart';

class WeeklyChart extends ConsumerWidget {
  const WeeklyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartData = ref.watch(weeklyChartDataProvider);
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.white;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final totalSales = chartData.fold<int>(0, (s, d) => s + d.income);
    final totalExpenses = chartData.fold<int>(0, (s, d) => s + d.expense);
    final net = totalSales - totalExpenses;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.14)
                : AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark
            ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.55))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: primaryTextColor.withValues(alpha: 0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUrdu
                        ? AppStrings.weeklyOverviewUrdu
                        : AppStrings.weeklyOverview,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SummaryPills(
            isUrdu: isUrdu,
            sales: totalSales,
            expenses: totalExpenses,
            net: net,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _LegendDot(
                color: const Color(0xFF1B6D24),
                label: isUrdu ? 'فروخت' : 'Sales',
              ),
              const SizedBox(width: 14),
              _LegendDot(
                color: isDark ? AppColors.errorReadable : AppColors.error,
                label: isUrdu ? 'خرچ' : 'Expense',
              ),
              const Spacer(),
              Text(
                isUrdu ? '7 دن' : 'Last 7 days',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 190,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: _buildBars(
                context,
                chartData,
                isDark,
                secondaryTextColor,
                primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBars(
    BuildContext context,
    List<DayChartData> data,
    bool isDark,
    Color secondaryTextColor,
    Color primaryTextColor,
  ) {
    final maxVal = data
        .map((e) => [e.income, e.expense, e.net.abs()].reduce((a, b) => a > b ? a : b))
        .fold(0, (a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(data.length, (index) {
        final day = data[index];
        final hasData = day.income > 0 || day.expense > 0;
        final incomeFactor =
            maxVal == 0 ? 0.0 : (day.income / maxVal).clamp(0.0, 1.0);
        final expenseFactor =
            maxVal == 0 ? 0.0 : (day.expense / maxVal).clamp(0.0, 1.0);
        final maxBarHeight = 120.0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasData)
                  Text(
                    _formatNet(day.net),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: day.net >= 0
                          ? (isDark ? AppColors.white : AppColors.actionGreen)
                          : (isDark
                              ? AppColors.errorReadable
                              : AppColors.error),
                    ),
                  )
                else
                  Text(
                    '—',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor.withValues(alpha: 0.7),
                    ),
                  ),
                const SizedBox(height: 4),
                SizedBox(
                  height: maxBarHeight,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 28,
                        height: maxBarHeight,
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.white : AppColors.primary)
                              .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (day.income > 0)
                            Container(
                              width: 22,
                              height: (maxBarHeight * 0.55 * incomeFactor)
                                  .clamp(6.0, maxBarHeight * 0.55),
                              decoration: BoxDecoration(
                                color: const Color(0xFF43A047),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          if (day.expense > 0)
                            Container(
                              width: 22,
                              height: (maxBarHeight * 0.35 * expenseFactor)
                                  .clamp(4.0, maxBarHeight * 0.35),
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.errorReadable
                                    : const Color(0xFFE57373),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          if (!hasData)
                            Container(
                              width: 22,
                              height: 10,
                              decoration: BoxDecoration(
                                color: secondaryTextColor
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: day.isToday
                      ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                      : EdgeInsets.zero,
                  decoration: day.isToday
                      ? BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        )
                      : null,
                  child: Text(
                    day.label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight:
                          day.isToday ? FontWeight.w800 : FontWeight.w600,
                      color: day.isToday
                          ? primaryTextColor
                          : secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _formatNet(int amount) {
    final abs = amount.abs();
    final prefix = amount < 0 ? '-' : '';
    if (abs >= 1000) {
      return '$prefix${(abs / 1000).toStringAsFixed(1)}k';
    }
    return '$prefix$abs';
  }
}

class _SummaryPills extends StatelessWidget {
  final bool isUrdu;
  final int sales;
  final int expenses;
  final int net;
  final bool isDark;

  const _SummaryPills({
    required this.isUrdu,
    required this.sales,
    required this.expenses,
    required this.net,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _pill(
            isUrdu ? 'فروخت' : 'Sales',
            'Rs ${_compact(sales)}',
            const Color(0xFF1B6D24),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _pill(
            isUrdu ? 'خرچ' : 'Expense',
            'Rs ${_compact(expenses)}',
            isDark ? AppColors.errorReadable : AppColors.error,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _pill(
            isUrdu ? 'خالص' : 'Net',
            'Rs ${_compact(net)}',
            net >= 0 ? AppColors.actionGreen : AppColors.error,
          ),
        ),
      ],
    );
  }

  String _compact(int n) {
    final abs = n.abs();
    final sign = n < 0 ? '-' : '';
    if (abs >= 1000) return '$sign${(abs / 1000).toStringAsFixed(1)}k';
    return '$sign$abs';
  }

  Widget _pill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
