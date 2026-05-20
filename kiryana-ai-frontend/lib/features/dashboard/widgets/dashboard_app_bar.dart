import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../settings/providers/profile_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/widgets/animated_topbar_logo.dart';
import 'how_it_works_dialog.dart';

class DashboardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isUrdu = ref.watch(languageProvider).languageCode == 'ur';
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        bottom: AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr, // Keep layout fixed
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const AnimatedTopBarLogo(size: 32),
                const SizedBox(width: AppSpacing.sm),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Kiryana',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: 'AI',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.actionGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => showHowItWorksDialog(context, ref),
                  tooltip: isUrdu ? 'یہ کیسے کام کرتا ہے' : 'How it works',
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => context.go('/settings'),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      image: profile.profilePicPath != null
                          ? DecorationImage(
                              image: kIsWeb
                                  ? NetworkImage(profile.profilePicPath!)
                                  : FileImage(File(profile.profilePicPath!))
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: profile.profilePicPath == null
                        ? Icon(
                            Icons.person,
                            color: AppColors.primary.withValues(alpha: 0.5),
                            size: 24,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
