import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/transaction_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';

class TransactionCard extends ConsumerWidget {
  final TransactionModel item;

  const TransactionCard({
    super.key,
    required this.item,
  });

  IconData _getIcon() {
    final title = item.titleEnglish.toLowerCase();
    
    if (title.contains('sugar') || title.contains('rice') || title.contains('flour') || title.contains('biscuit')) {
      return Icons.shopping_bag_outlined;
    } else if (title.contains('transport') || title.contains('delivery') || title.contains('fuel')) {
      return Icons.local_shipping_outlined;
    } else if (title.contains('egg') || title.contains('milk') || title.contains('bread') || title.contains('food')) {
      return Icons.fastfood_outlined;
    } else if (title.contains('bill') || title.contains('electric') || title.contains('water')) {
      return Icons.bolt_outlined;
    } else if (title.contains('rent') || title.contains('shop') || title.contains('property')) {
      return Icons.storefront_outlined;
    } else if (title.contains('payment') || title.contains('cash') || title.contains('salary')) {
      return Icons.payments_outlined;
    }
    
    // Default generic icon if no keywords match
    return item.isSale ? Icons.shopping_basket_outlined : Icons.receipt_long_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = item.isSale
        ? (isDark ? AppColors.white : AppColors.actionGreen)
        : (isDark ? AppColors.errorReadable : AppColors.error);
    final bgColor = item.isSale ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';
    final cardColor = isDark ? AppColors.darkCard : AppColors.white;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.14) : AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.55)) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(
                color: color,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Directionality(
            textDirection: TextDirection.ltr, // Keep layout fixed like English
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                
                // Titles and Details - Always left aligned
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              isUrdu ? item.titleUrdu : item.titleEnglish,
                              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                              overflow: TextOverflow.ellipsis,
                              style: isUrdu
                                  ? TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                )
                                  : GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              item.timeString,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.primary.withValues(alpha: 0.42) : AppColors.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.tag,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                
                // Amount and Type - Always right aligned for clean edge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.isSale ? '+' : '-'} Rs. ${item.amount}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUrdu 
                        ? (item.isSale ? AppStrings.saleUrdu : AppStrings.manualExpenseUrdu)
                        : (item.isSale ? AppStrings.saleEnglish : AppStrings.expenseEnglish),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
