import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';

class VoiceActionButtons extends ConsumerWidget {
  final VoidCallback onCorrect;
  final VoidCallback onRetry;
  final bool isBusy;

  const VoiceActionButtons({
    super.key,
    required this.onCorrect,
    required this.onRetry,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Correct Button
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isBusy ? null : onCorrect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionGreen,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          isUrdu ? AppStrings.correctEnglish : AppStrings.correctEnglish,
                          style: TextStyle(
                            fontSize: isUrdu ? 14 : 16,
                            fontWeight: isUrdu ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                        if (isUrdu) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const Text(
                            AppStrings.correctUrdu,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Retry Button
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: isBusy ? null : onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                    side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          isUrdu ? AppStrings.retryEnglish : AppStrings.retryEnglish,
                          style: TextStyle(
                            fontSize: isUrdu ? 14 : 16,
                            fontWeight: isUrdu ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                        if (isUrdu) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const Text(
                            AppStrings.retryUrdu,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
