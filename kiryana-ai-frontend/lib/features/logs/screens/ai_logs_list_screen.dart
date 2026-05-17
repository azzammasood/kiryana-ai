import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../data/mock/mock_ai_logs_data.dart';
import '../../dashboard/widgets/custom_bottom_nav.dart';
import '../../settings/providers/profile_provider.dart';

class AiLogsListScreen extends StatelessWidget {
  const AiLogsListScreen({super.key});

  void _onNavTap(BuildContext context, int index) {
    if (index == 0) {
      context.go('/dashboard');
    } else if (index == 1) {
      context.pop(); // Go back to regular logs
    } else if (index == 2) {
      context.go('/insights');
    } else if (index == 3) {
      context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= AppSpacing.mobileBreakpoint;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const sessions = MockAiLogsData.sessions;

    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : AppColors.secondary,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + AppSpacing.sm),
        child: Container(
          color: AppColors.primary,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: AppSpacing.sm,
            left: AppSpacing.sm,
            right: AppSpacing.md,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
                Text(
                  'AI Sessions',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const Spacer(),
                // Profile Picture
                Consumer(
                  builder: (context, ref, child) {
                    final profile = ref.watch(profileProvider);
                    return GestureDetector(
                      onTap: () => context.go('/settings'),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.white.withValues(alpha: 0.2),
                        backgroundImage: profile.profilePicPath != null
                            ? (kIsWeb 
                                ? NetworkImage(profile.profilePicPath!) 
                                : FileImage(File(profile.profilePicPath!)) as ImageProvider)
                            : null,
                        child: profile.profilePicPath == null
                            ? const Icon(Icons.person_rounded, color: AppColors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? AppSpacing.maxContentWidth : double.infinity,
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: InkWell(
                    onTap: () {
                      context.push('/ai-logs/${session.traceId}');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
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
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.primaryLight : AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.memory_rounded, color: isDark ? AppColors.white : AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.summary,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        session.traceId,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '•  ${session.date}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: isWide 
          ? null 
          : CustomBottomNav(
              currentIndex: 1,
              onTap: (index) => _onNavTap(context, index),
            ),
    );
  }
}
