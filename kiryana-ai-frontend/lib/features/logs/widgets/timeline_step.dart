import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../data/mock/mock_ai_logs_data.dart';
import '../../../../core/constants/app_strings.dart';

class TimelineStep extends StatelessWidget {
  final AiLogStep step;
  final bool isLast;

  const TimelineStep({
    super.key,
    required this.step,
    this.isLast = false,
  });

  Widget _buildIcon() {
    Color bgColor;
    Color iconColor;
    Color borderColor = Colors.transparent;

    switch (step.type) {
      case AiLogStepType.input:
      case AiLogStepType.parsed:
        bgColor = AppColors.white;
        iconColor = AppColors.textSecondary;
        borderColor = AppColors.textSecondary.withValues(alpha: 0.3);
        break;
      case AiLogStepType.insight:
        bgColor = AppColors.white;
        iconColor = AppColors.primary;
        borderColor = AppColors.primary;
        break;
      case AiLogStepType.action:
        bgColor = const Color(0xFF1B5E20); // Darker green
        iconColor = AppColors.white;
        break;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          step.icon,
          color: iconColor,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (step.type) {
      case AiLogStepType.input:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.white.withValues(alpha: 0.1) : const Color(0xFFEBEBEB),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: isDark ? AppColors.actionGreen : AppColors.primary, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"Sold 500 Rs Atta"',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.rawVoiceAudioTranscriptEnglish,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );

      case AiLogStepType.parsed:
        return Container(
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Item', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Atta', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Amount', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Rs. 500', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1B5E20))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Sale', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1B5E20))),
                  ],
                ),
              ),
            ],
          ),
        );

      case AiLogStepType.insight:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.primaryLight : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: isDark ? AppColors.white : AppColors.primary, width: 4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: isDark ? AppColors.white : AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sales drop detected for Flour compared to last week.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? AppColors.white : AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );

      case AiLogStepType.action:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
          ),
          child: Text(
            'Dashboard updated successfully.\nTransaction committed to ledger.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line & Icon
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _buildIcon(),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: isDark ? AppColors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          
          // Step Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        step.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.white : (step.type == AiLogStepType.insight ? AppColors.primary : AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        step.time,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.white.withValues(alpha: 0.6) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  _buildContent(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
