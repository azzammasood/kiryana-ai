import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../settings/providers/profile_provider.dart';

class DashboardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo & Title
            Row(
              children: [
                Image.asset(
                  'assets/images/topbar-logo.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: AppSpacing.sm),
                // Title
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
            
            // Profile Picture
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
                              : FileImage(File(profile.profilePicPath!)) as ImageProvider,
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
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
