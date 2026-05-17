import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// PlaceholderImageWidget
/// Used wherever real images/illustrations will be placed later.
/// Supports custom size, border radius, label/numbering.
class PlaceholderImageWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final String label;
  final Color? backgroundColor;
  final Color? labelColor;
  final IconData? icon;

  const PlaceholderImageWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppSpacing.radiusMd,
    required this.label,
    this.backgroundColor,
    this.labelColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.secondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.border,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.image_outlined,
            size: AppSpacing.iconXl,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: labelColor ?? AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// PlaceholderAvatar
/// Used for user/store profile avatars before real assets are provided.
class PlaceholderAvatar extends StatelessWidget {
  final double size;
  final String label;
  final Color? backgroundColor;

  const PlaceholderAvatar({
    super.key,
    this.size = 48,
    this.label = 'Avatar',
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: size * 0.5,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}

/// PlaceholderBanner
/// Full-width banner placeholder for promotional/hero sections.
class PlaceholderBanner extends StatelessWidget {
  final double? height;
  final String label;
  final double borderRadius;

  const PlaceholderBanner({
    super.key,
    this.height = 160,
    required this.label,
    this.borderRadius = AppSpacing.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    return PlaceholderImageWidget(
      width: double.infinity,
      height: height,
      borderRadius: borderRadius,
      label: label,
      icon: Icons.image_outlined,
      backgroundColor: AppColors.secondary.withValues(alpha: 0.3),
    );
  }
}

/// OnboardingIllustrationPlaceholder
/// Specific placeholder sized for onboarding screen illustrations.
class OnboardingIllustrationPlaceholder extends StatelessWidget {
  final int index;
  final double size;

  const OnboardingIllustrationPlaceholder({
    super.key,
    required this.index,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    return PlaceholderImageWidget(
      width: size,
      height: size,
      borderRadius: AppSpacing.radiusLg,
      label: 'Illustration $index',
      backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
      icon: Icons.person_outline,
    );
  }
}
