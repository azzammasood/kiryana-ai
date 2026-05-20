import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import 'package:kiryana_ai/features/logs/providers/transaction_provider.dart';

import '../../../core/providers/language_provider.dart';

class SummaryCards extends ConsumerWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatCurrency = NumberFormat('#,##0', 'en_US');
    final todaySales = ref.watch(todaySalesProvider);
    final todayExpenses = ref.watch(todayExpensesProvider);
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header - English on left, Urdu on right (if available)
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: isUrdu ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
            children: [
              Text(
                isUrdu ? AppStrings.todaysSummaryUrdu : AppStrings.todaysSummary,
                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Cards Row - Forced LTR to keep Expenses left and Sales right
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              // Expenses Card - Always on Left
              Expanded(
                child: _SummaryCard(
                  isUrdu: isUrdu,
                  isExpense: true,
                  titleUrdu: AppStrings.expensesUrdu,
                  titleEnglish: AppStrings.expenses,
                  amount: '- Rs\n${formatCurrency.format(todayExpenses)}',
                  amountColor: isDark ? AppColors.errorReadable : AppColors.error,
                  icon: Icons.trending_down_rounded,
                  iconBgColor: const Color(0xFFFFEBEE),
                  iconColor: const Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Sales Card - Always on Right
              Expanded(
                child: _SummaryCard(
                  isUrdu: isUrdu,
                  isExpense: false,
                  titleUrdu: AppStrings.salesUrdu,
                  titleEnglish: AppStrings.sales,
                  amount: '+ Rs\n${formatCurrency.format(todaySales)}',
                  amountColor: isDark ? AppColors.white : AppColors.actionGreen,
                  icon: Icons.trending_up_rounded,
                  iconBgColor: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF1B6D24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final bool isUrdu;
  final bool isExpense;
  final String titleUrdu;
  final String titleEnglish;
  final String amount;
  final Color amountColor;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const _SummaryCard({
    required this.isUrdu,
    required this.isExpense,
    required this.titleUrdu,
    required this.titleEnglish,
    required this.amount,
    required this.amountColor,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.white;
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.14) : AppColors.primary.withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.55)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            // Navigate to logs/transactions page
            context.go('/transactions');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIcon(),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTitles(isDark)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  amount,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: iconBgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 16,
        color: iconColor,
      ),
    );
  }

  Widget _buildTitles(bool isDark) {
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return Column(
      crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (isUrdu)
          Text(
            titleUrdu,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),
        if (!isUrdu)
          Text(
            titleEnglish,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primaryTextColor,
            ),
          ),
      ],
    );
  }
}
