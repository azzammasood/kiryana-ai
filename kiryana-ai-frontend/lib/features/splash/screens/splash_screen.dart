import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

/// SplashScreen — matches Figma design.
/// Background: #00464A (primary teal)
/// Logo: numbered placeholder box [Logo Image] until real asset provided
/// "KiryanaAI" with "AI" in bright green
/// Urdu tagline: default system font (no custom font override)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );



    _controller.forward();

    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    await Future.delayed(const Duration(milliseconds: 2400));
    
    if (mounted) {
      if (isLoggedIn) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
              ),
            ),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo Image ───────────────────────────
                  Image.asset(
                    'assets/images/splashLogo.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
                  ),

              const SizedBox(height: AppSpacing.lg),

              // ── "KiryanaAI" — Kiryana white, AI bright green ─────
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Kiryana',
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'AI',
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4AE54A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xs + 2),

              // ── English subtitle ─────────────────────────────────
              Text(
                'Voice-First Expense Manager',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Urdu tagline — default system font, no override ──
              Text(
                'آپ کی دکان کا سمارٹ ساتھی',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white.withValues(alpha: 0.90),
                  height: 1.8,
                ),
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
