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
    final color = item.isSale ? AppColors.actionGreen : const Color(0xFFD32F2F);
    final bgColor = item.isSale ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                              item.titleEnglish,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: isUrdu ? 12 : 16,
                                fontWeight: isUrdu ? FontWeight.w600 : FontWeight.w700,
                                color: isUrdu ? AppColors.textSecondary : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isUrdu) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                item.titleUrdu,
                                textDirection: TextDirection.rtl,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
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
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.tag,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
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
                        ? '${item.isSale ? AppStrings.saleEnglish : AppStrings.expenseEnglish} (${item.isSale ? AppStrings.saleUrdu : AppStrings.manualExpenseUrdu})' 
                        : (item.isSale ? AppStrings.saleEnglish : AppStrings.expenseEnglish),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
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
