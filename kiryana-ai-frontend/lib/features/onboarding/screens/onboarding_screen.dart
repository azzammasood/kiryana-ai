import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/onboarding_model.dart';
import '../providers/onboarding_provider.dart';

/// OnboardingScreen
/// ─ NO skip button
/// ─ Swipeable PageView (default physics) + left/right arrow buttons
/// ─ Left arrow inactive on page 0, right arrow inactive on last page
/// ─ Tappable dots for direct navigation
/// ─ Last slide shows "شروع کریں" green button
/// ─ All Urdu/English text uses default system font, primary color, centered
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(onboardingPageIndexProvider.notifier).goToPage(index);
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(onboardingPagesProvider);
    final currentIndex = ref.watch(onboardingPageIndexProvider);
    final isLastPage = currentIndex == pages.length - 1;
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= AppSpacing.mobileBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? AppSpacing.maxContentWidth : double.infinity,
              ),
              child: Column(
                children: [
                  // ── Swipeable PageView ───────────────────────────
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      // Swipe enabled (default physics)
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: _onPageChanged,
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        return _OnboardingPage(
                          model: pages[index],
                          isActive: index == currentIndex,
                        );
                      },
                    ),
                  ),
  
                  // ── Bottom Navigation Bar ────────────────────────
                  _BottomNav(
                    currentIndex: currentIndex,
                    total: pages.length,
                    isLastPage: isLastPage,
                    onPrev: () => _goToPage(currentIndex - 1),
                    onNext: () => _goToPage(currentIndex + 1),
                    onDotTapped: _goToPage,
                    onGetStarted: _navigateToLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────
// Contains: [←] [• • •] [→]  with arrows disabled at extremes
// Last page: arrows hidden, "شروع کریں" button shown
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final int total;
  final bool isLastPage;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onDotTapped;
  final VoidCallback onGetStarted;

  const _BottomNav({
    required this.currentIndex,
    required this.total,
    required this.isLastPage,
    required this.onPrev,
    required this.onNext,
    required this.onDotTapped,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFirst = currentIndex == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Arrow + Dots row ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left arrow
              _NavArrow(
                icon: Icons.arrow_back_ios_new_rounded,
                enabled: !isFirst,
                onTap: onPrev,
              ),

              const SizedBox(width: AppSpacing.md),

              // Dot indicators
              _DotIndicator(
                currentIndex: currentIndex,
                totalCount: total,
                onDotTapped: onDotTapped,
              ),

              const SizedBox(width: AppSpacing.md),

              // Right arrow — hidden on last page, disabled on last page
              _NavArrow(
                icon: Icons.arrow_forward_ios_rounded,
                enabled: !isLastPage,
                onTap: onNext,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Button area (fixed height to prevent layout jump) ─
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: isLastPage
                ? _GetStartedButton(
                    key: const ValueKey('btn'),
                    onPressed: onGetStarted,
                  )
                : const SizedBox(key: ValueKey('empty'), height: 80),
          ),
        ],
      ),
    );
  }
}

// ── Nav Arrow Button ──────────────────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.secondary,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.primary : AppColors.secondary,
        ),
      ),
    );
  }
}

// ── Individual Onboarding Page ────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final OnboardingPageModel model;
  final bool isActive;

  const _OnboardingPage({
    required this.model,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Illustration: ~30% of screen height, capped 180–260px
    final illustrationSize = (size.height * 0.30).clamp(180.0, 260.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Top spacing — pushes illustration higher on screen
          SizedBox(height: size.height * 0.06),

          // ── Illustration Image ───────────────────────────────
          Image.asset(
            model.imagePath,
            height: illustrationSize,
            fit: BoxFit.contain,
          ),

          // Generous gap between illustration and text
          SizedBox(height: size.height * 0.07),

          // ── Urdu Title ─────────────────────────────────────
          Text(
            model.titleUrdu,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.6,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── English Subtitle ───────────────────────────────
          Text(
            model.subtitleEn,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.primary.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tappable Dot Indicator ────────────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final ValueChanged<int> onDotTapped;

  const _DotIndicator({
    required this.currentIndex,
    required this.totalCount,
    required this.onDotTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalCount, (index) {
        final bool isActive = index == currentIndex;
        return GestureDetector(
          onTap: () => onDotTapped(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.secondary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
        );
      }),
    );
  }
}

// ── Get Started Button (last slide only) ─────────────────────────────────────
class _GetStartedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GetStartedButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "شروع کریں" — default system font (Urdu renders naturally)
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionGreen,
              foregroundColor: AppColors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.ltr,
              children: [
                Text(
                  AppStrings.getStartedUrdu,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(width: 10),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Icon(Icons.arrow_forward_rounded, size: 22, color: AppColors.white),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // English sublabel
        const Text(
          AppStrings.getStarted,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
