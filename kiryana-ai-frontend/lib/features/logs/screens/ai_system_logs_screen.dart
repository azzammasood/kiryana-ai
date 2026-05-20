import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/api_service.dart';
import '../../dashboard/widgets/custom_bottom_nav.dart';
import '../../settings/providers/profile_provider.dart';
import '../widgets/timeline_step.dart';
import '../models/agent_trace_model.dart';
import '../../../core/providers/language_provider.dart';

class AiSystemLogsScreen extends ConsumerStatefulWidget {
  final String traceId;

  const AiSystemLogsScreen({super.key, required this.traceId});

  @override
  ConsumerState<AiSystemLogsScreen> createState() => _AiSystemLogsScreenState();
}

class _AiSystemLogsScreenState extends ConsumerState<AiSystemLogsScreen> {
  late final Future<List<AgentTraceStep>> _traceFuture;

  @override
  void initState() {
    super.initState();
    _traceFuture = _loadTrace();
  }

  Future<List<AgentTraceStep>> _loadTrace() async {
    final userId = await ApiService().currentUserId();
    final rows = await ApiService().getAgentTraceBySession(userId, widget.traceId);
    return rows
        .map((row) => AgentTraceStep.fromApi(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  void _onNavTap(int index) {
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
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
                Text(
                  isUrdu ? 'AI سسٹم لاگز' : AppStrings.aiSystemLogsEnglish,
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
                                : FileImage(File(profile.profilePicPath!))
                                    as ImageProvider)
                            : null,
                        child: profile.profilePicPath == null
                            ? const Icon(Icons.person_rounded,
                                color: AppColors.white, size: 20)
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
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.aiPurple,
                              AppColors.aiBlue,
                              AppColors.aiPink,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        isUrdu
                            ? AppStrings.aiSystemLogsUrdu
                            : AppStrings.aiSystemLogsEnglish,
                        textDirection:
                            isUrdu ? TextDirection.rtl : TextDirection.ltr,
                        style: isUrdu
                            ? TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.primary)
                            : GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Trace ID Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.traceIdEnglish,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          widget.traceId,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.sessionEnglish,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              AppStrings.voiceInputProcessorEnglish,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  FutureBuilder<List<AgentTraceStep>>(
                    future: _traceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text(
                          ApiService().errorMessage(snapshot.error!),
                          style: GoogleFonts.inter(color: AppColors.errorReadable),
                        );
                      }
                      final steps = snapshot.data ?? const <AgentTraceStep>[];
                      if (steps.isEmpty) {
                        return Text(
                          'No trace data available.',
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        );
                      }
                      return Column(
                        children: List.generate(steps.length, (index) {
                          return TimelineStep(
                            step: steps[index],
                            isLast: index == steps.length - 1,
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : CustomBottomNav(
              currentIndex:
                  1, // Logs is technically still the active tab conceptually
              onTap: _onNavTap,
            ),
    );
  }
}
