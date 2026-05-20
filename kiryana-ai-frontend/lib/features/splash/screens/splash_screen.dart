import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

/// Splash — logo asset already includes app name + English tagline.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _enterDuration = Duration(milliseconds: 1000);
  static const _exitDuration = Duration(milliseconds: 550);
  static const _holdDuration = Duration(milliseconds: 1500);

  late final AnimationController _enterController;
  late final AnimationController _exitController;

  late final Animation<double> _logoEnterFade;
  late final Animation<double> _logoEnterScale;
  late final Animation<double> _taglineEnterFade;
  late final Animation<Offset> _taglineEnterSlide;

  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;
  late final Animation<Offset> _exitSlide;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: _enterDuration,
    );
    _exitController = AnimationController(
      vsync: this,
      duration: _exitDuration,
    );

    _logoEnterFade = CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.0, 0.72, curve: Curves.easeInOutCubic),
    );

    _logoEnterScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.0, 0.78, curve: Curves.easeOutCubic),
      ),
    );

    _taglineEnterFade = CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.32, 0.88, curve: Curves.easeInOutCubic),
    );

    _taglineEnterSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.32, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    _exitSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.04),
    ).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    await _enterController.forward();
    if (!mounted) return;

    await Future<void>.delayed(_holdDuration);
    if (!mounted) return;

    await _exitController.forward();
    if (!mounted) return;

    if (isLoggedIn) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_enterController, _exitController]),
          builder: (context, child) {
            final exitFade = _exitFade.value;
            final exitScale = _exitScale.value;
            final exitSlide = _exitSlide.value;

            return FadeTransition(
              opacity: AlwaysStoppedAnimation(exitFade),
              child: Transform.scale(
                scale: exitScale,
                child: Transform.translate(
                  offset: Offset(0, exitSlide.dy * 24),
                  child: child,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoEnterFade,
                  child: ScaleTransition(
                    scale: _logoEnterScale,
                    child: Image.asset(
                      'assets/images/splashLogo.png',
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeTransition(
                  opacity: _taglineEnterFade,
                  child: SlideTransition(
                    position: _taglineEnterSlide,
                    child: Text(
                      'آپ کی دکان کا سمارٹ ساتھی',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white.withValues(alpha: 0.92),
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
