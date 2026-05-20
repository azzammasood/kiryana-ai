import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';

class ParsedDetailsCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  const ParsedDetailsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSale =
        data['transaction_type'] == 'sale' || data['is_sale'] == true;
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Top colored border
            Container(
              height: 4,
              color: isSale ? AppColors.actionGreen : const Color(0xFFD32F2F),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag (Sale/Expense)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSale
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isSale ? AppStrings.saleEnglish : 'Expense',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSale
                                    ? AppColors.actionGreen
                                    : const Color(0xFFD32F2F),
                              ),
                            ),
                            if (isUrdu) const SizedBox(width: 4),
                            if (isUrdu)
                              Text(
                                isSale
                                    ? '(${AppStrings.saleUrdu})'
                                    : '(اخراجات)',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSale
                                      ? AppColors.actionGreen
                                      : const Color(0xFFD32F2F),
                                ),
                              ),
                            const SizedBox(width: 4),
                            Icon(
                              isSale
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 14,
                              color: isSale
                                  ? AppColors.actionGreen
                                  : const Color(0xFFD32F2F),
                            ),
                          ],
                        ),
                      ),

                      // "Parsed Details" text + Icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: isUrdu
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (isUrdu)
                                const Text(
                                  AppStrings.parsedDetailsUrdu,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              Text(
                                AppStrings.parsedDetailsEnglish,
                                style: GoogleFonts.inter(
                                  fontSize: isUrdu ? 10 : 14,
                                  fontWeight: isUrdu
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: isUrdu
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),
                  Divider(color: AppColors.primary.withValues(alpha: 0.1)),
                  const SizedBox(height: AppSpacing.md),

                  // Detail Rows
                  _buildDetailRow(
                    isUrdu: isUrdu,
                    urduLabel: AppStrings.itemUrdu,
                    engLabel: AppStrings.itemEnglish,
                    urduVal: data['item_name_urdu']?.toString(),
                    engVal: (data['item_name'] ?? data['item_english'] ?? '')
                        .toString(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDetailRow(
                    isUrdu: isUrdu,
                    urduLabel: AppStrings.qtyUrdu,
                    engLabel: AppStrings.qtyEnglish,
                    engVal: '${data['quantity'] ?? '-'} ${data['unit'] ?? ''}'
                        .trim(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDetailRow(
                    isUrdu: isUrdu,
                    urduLabel: AppStrings.amountUrdu,
                    engLabel: AppStrings.amountEnglish,
                    engVal: ((data['amount'] ?? data['price'] ?? 0)).toString(),
                    isAmount: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required bool isUrdu,
    required String urduLabel,
    required String engLabel,
    String? urduVal,
    required String engVal,
    bool isAmount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Label on Left (if English mode) or Value on Left (if Urdu mode)
        if (!isUrdu)
          Text(
            engLabel,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),

        if (isUrdu)
          Row(
            children: [
              if (urduVal != null) ...[
                Text(
                  '$urduVal ',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: isAmount ? 18 : 14,
                    fontWeight: isAmount ? FontWeight.w800 : FontWeight.w700,
                    color: isAmount
                        ? AppColors.actionGreen
                        : AppColors.textPrimary,
                  ),
                ),
              ],
              Text(
                urduVal != null ? '($engVal)' : engVal,
                style: GoogleFonts.inter(
                  fontSize: isAmount ? 18 : 14,
                  fontWeight: isAmount ? FontWeight.w800 : FontWeight.w700,
                  color:
                      isAmount ? AppColors.actionGreen : AppColors.textPrimary,
                ),
              ),
            ],
          ),

        // Value on Right (if English mode) or Label on Right (if Urdu mode)
        if (!isUrdu)
          Text(
            isAmount ? 'Rs. $engVal' : engVal,
            style: GoogleFonts.inter(
              fontSize: isAmount ? 18 : 15,
              fontWeight: isAmount ? FontWeight.w800 : FontWeight.w700,
              color: isAmount ? AppColors.actionGreen : AppColors.textPrimary,
            ),
          ),

        if (isUrdu)
          Row(
            children: [
              Text(
                engLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                ':$urduLabel',
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
