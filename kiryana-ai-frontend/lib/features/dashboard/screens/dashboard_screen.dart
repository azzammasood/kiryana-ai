import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/summary_cards.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/insight_banner.dart';
import '../widgets/speak_button_card.dart';
import '../widgets/custom_bottom_nav.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    if (index == 1) {
      context.go('/logs');
    } else if (index == 2) {
      context.go('/insights');
    } else if (index == 3) {
      context.go('/settings');
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _onSpeakTap() {
    context.push('/voice-input');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= AppSpacing.mobileBreakpoint;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : AppColors.secondary,
      appBar: const DashboardAppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? AppSpacing.maxContentWidth : double.infinity,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                const SummaryCards(),
                const SizedBox(height: AppSpacing.lg),
                const WeeklyChart(),
                const SizedBox(height: AppSpacing.lg),
                const InsightBanner(),
                const SizedBox(height: AppSpacing.lg),
                SpeakButtonCard(onTap: _onSpeakTap),
                const SizedBox(height: AppSpacing.xxl), // padding for bottom nav
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isWide 
          ? null // Bottom nav might be handled differently on wide screens later
          : CustomBottomNav(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
    );
  }
}
