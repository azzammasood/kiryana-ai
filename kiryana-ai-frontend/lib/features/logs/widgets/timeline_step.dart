import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../models/agent_trace_model.dart';

class TimelineStep extends StatelessWidget {
  final AgentTraceStep step;
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
      case AgentStepType.input:
      case AgentStepType.parsed:
        bgColor = AppColors.white;
        iconColor = AppColors.textSecondary;
        borderColor = AppColors.textSecondary.withValues(alpha: 0.3);
        break;
      case AgentStepType.insight:
        bgColor = AppColors.white;
        iconColor = AppColors.primary;
        borderColor = AppColors.primary;
        break;
      case AgentStepType.action:
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryLight : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: step.status == 'success'
              ? (isDark ? AppColors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.15))
              : AppColors.errorReadable.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        step.detail,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.white : AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
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
                          color: isDark ? AppColors.white : (step.type == AgentStepType.insight ? AppColors.primary : AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        step.timeLabel,
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
