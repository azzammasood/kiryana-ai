import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

/// Splash screen with a polished brand reveal before routing into the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _enterDuration = Duration(milliseconds: 1250);
  static const _exitDuration = Duration(milliseconds: 620);
  static const _holdDuration = Duration(milliseconds: 1850);

  late final AnimationController _enterController;
  late final AnimationController _exitController;
  late final AnimationController _ambientController;

  late final Animation<double> _logoEnterFade;
  late final Animation<double> _logoEnterScale;
  late final Animation<Offset> _logoEnterSlide;
  late final Animation<double> _taglineEnterFade;
  late final Animation<Offset> _taglineEnterSlide;
  late final Animation<double> _meterEnterFade;

  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;
  late final Animation<Offset> _exitSlide;
  bool _didStartSessionCheck = false;

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
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    )..repeat();

    _logoEnterFade = CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.0, 0.58, curve: Curves.easeOutCubic),
    );

    _logoEnterScale = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOutBack),
      ),
    );

    _logoEnterSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.0, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    _taglineEnterFade = CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.34, 0.84, curve: Curves.easeOutCubic),
    );

    _taglineEnterSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.34, 0.84, curve: Curves.easeOutCubic),
      ),
    );

    _meterEnterFade = CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.56, 1.0, curve: Curves.easeOutCubic),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    _exitSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.04),
    ).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartSessionCheck) return;

    _didStartSessionCheck = true;
    _checkSession();
  }

  Future<void> _warmSplashAssets() async {
    try {
      await Future.wait<void>([
        precacheImage(
          const AssetImage('assets/images/splashLogo.png'),
          context,
        ),
        GoogleFonts.pendingFonts([
          GoogleFonts.notoNastaliqUrdu(fontWeight: FontWeight.w600),
        ]).then((_) {}),
      ]).timeout(const Duration(milliseconds: 1800));
    } catch (_) {
      // Continue the splash even if a preload is interrupted by the browser.
    }
  }

  Future<void> _checkSession() async {
    final prefsFuture = SharedPreferences.getInstance();

    await _warmSplashAssets();
    if (!mounted) return;

    final prefs = await prefsFuture;
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
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.height < 700;
    final logoWidth = math.min(size.width * 0.58, isCompact ? 190.0 : 220.0);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, _) {
              return CustomPaint(
                painter: _SplashBackdropPainter(
                  progress: _ambientController.value,
                ),
              );
            },
          ),
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _enterController,
                  _exitController,
                  _ambientController,
                ]),
                builder: (context, _) {
                  final dy = _exitSlide.value.dy * 34;

                  return FadeTransition(
                    opacity: _exitFade,
                    child: Transform.translate(
                      offset: Offset(0, dy),
                      child: Transform.scale(
                        scale: _exitScale.value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSpacing.maxContentWidth,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _LogoReveal(
                                  fade: _logoEnterFade,
                                  scale: _logoEnterScale,
                                  slide: _logoEnterSlide,
                                  progress: _ambientController.value,
                                  logoWidth: logoWidth,
                                  isCompact: isCompact,
                                ),
                                SizedBox(
                                  height: isCompact ? AppSpacing.lg : 40,
                                ),
                                FadeTransition(
                                  opacity: _taglineEnterFade,
                                  child: SlideTransition(
                                    position: _taglineEnterSlide,
                                    child: Text(
                                      'آپ کی دکان کا سمارٹ ساتھی',
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.notoNastaliqUrdu(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.white
                                            .withValues(alpha: 0.96),
                                        height: 1.7,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: isCompact ? AppSpacing.lg : 34,
                                ),
                                FadeTransition(
                                  opacity: _meterEnterFade,
                                  child: _LoadingMeter(
                                    progress: _ambientController.value,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoReveal extends StatelessWidget {
  const _LogoReveal({
    required this.fade,
    required this.scale,
    required this.slide,
    required this.progress,
    required this.logoWidth,
    required this.isCompact,
  });

  final Animation<double> fade;
  final Animation<double> scale;
  final Animation<Offset> slide;
  final double progress;
  final double logoWidth;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final breathe = 1 + (math.sin(progress * math.pi * 2) * 0.012);
    final floatY = math.sin((progress * math.pi * 2) + 0.45) * 5;
    final panelWidth = logoWidth + 62;

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.scale(
            scale: scale.value * breathe,
            child: SizedBox(
              width: panelWidth,
              height: isCompact ? 190 : 218,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LogoHaloPainter(progress: progress),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        width: panelWidth - 18,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.07),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primaryDark.withValues(alpha: 0.36),
                              blurRadius: 34,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/splashLogo.png',
                          width: logoWidth,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                        ),
                      ),
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

class _LoadingMeter extends StatelessWidget {
  const _LoadingMeter({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 104,
          height: 24,
          child: CustomPaint(
            painter: _LoadingMeterPainter(progress: progress),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Opacity(
          opacity: 0.74 + (math.sin(progress * math.pi * 2) * 0.12),
          child: Text(
            'Loading your smart dukaan',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.white.withValues(alpha: 0.8),
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashBackdropPainter extends CustomPainter {
  const _SplashBackdropPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final phase = progress * math.pi * 2;

    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF002D30),
          Color(0xFF00464A),
          Color(0xFF053E34),
        ],
        stops: [0, 0.58, 1],
      ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    _drawAnimatedSweep(canvas, size, phase);
    _drawLedgerLines(canvas, size, phase);
    _drawBottomWave(canvas, size, phase);
    _drawSoftVignette(canvas, rect);
  }

  void _drawAnimatedSweep(Canvas canvas, Size size, double phase) {
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          const Color(0xFF30D86A).withValues(alpha: 0.07),
          AppColors.white.withValues(alpha: 0.035),
          Colors.transparent,
        ],
        stops: const [0, 0.38, 0.58, 1],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width * 1.25, 130),
      );

    final offset = (math.sin(phase * 0.7) * 28) + (size.width * 0.08);
    canvas.save();
    canvas.translate(offset, size.height * 0.2);
    canvas.rotate(-0.32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-size.width * 0.24, 0, size.width * 1.42, 126),
        const Radius.circular(14),
      ),
      bandPaint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(size.width - offset, size.height * 0.73);
    canvas.rotate(-0.32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-size.width * 0.72, 0, size.width * 1.16, 86),
        const Radius.circular(14),
      ),
      bandPaint..color = AppColors.white.withValues(alpha: 0.02),
    );
    canvas.restore();
  }

  void _drawLedgerLines(Canvas canvas, Size size, double phase) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2
      ..color = AppColors.white.withValues(alpha: 0.055);

    final dashPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.white.withValues(alpha: 0.08);

    for (var i = 0; i < 9; i++) {
      final y =
          size.height * (0.13 + (i * 0.083)) + math.sin(phase + i * 0.9) * 7;
      final leftLength = size.width * (0.12 + ((i % 3) * 0.035));
      final rightLength = size.width * (0.1 + (((i + 1) % 3) * 0.04));

      canvas.drawLine(
        Offset(size.width * 0.07, y),
        Offset(size.width * 0.07 + leftLength, y),
        linePaint,
      );
      canvas.drawLine(
        Offset(size.width * 0.93 - rightLength, y + 16),
        Offset(size.width * 0.93, y + 16),
        linePaint,
      );

      if (i.isEven) {
        final pulse = 0.5 + (math.sin(phase * 1.8 + i) * 0.5);
        final dashWidth = 16 + (pulse * 14);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.09,
              y + 11,
              dashWidth,
              3,
            ),
            const Radius.circular(3),
          ),
          dashPaint,
        );
      }
    }
  }

  void _drawBottomWave(Canvas canvas, Size size, double phase) {
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF30D86A).withValues(alpha: 0.14);

    final path = Path();
    final baseY = size.height * 0.84;
    final amplitude = math.max(10.0, size.height * 0.014);
    for (var x = 0.0; x <= size.width; x += 8) {
      final y = baseY +
          math.sin((x / size.width * math.pi * 3.2) + phase) * amplitude;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, wavePaint);
  }

  void _drawSoftVignette(Canvas canvas, Rect rect) {
    final vignettePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x33001A1C),
          Colors.transparent,
          Color(0x52001A1C),
        ],
        stops: [0, 0.45, 1],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant _SplashBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _LogoHaloPainter extends CustomPainter {
  const _LogoHaloPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shortest = math.min(size.width, size.height);
    final phase = progress * math.pi * 2;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF30D86A).withValues(alpha: 0.28);

    for (var i = 0; i < 3; i++) {
      final radius = (shortest * 0.36) + (i * 18);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final start = phase * (0.35 + i * 0.12) + (i * math.pi * 0.62);
      final sweep = math.pi * (0.24 + (i * 0.07));

      canvas.drawArc(rect, start, sweep, false, glowPaint);
      canvas.drawArc(
        rect,
        start + math.pi,
        sweep * 0.58,
        false,
        glowPaint..color = AppColors.white.withValues(alpha: 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LogoHaloPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _LoadingMeterPainter extends CustomPainter {
  const _LoadingMeterPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 5;
    final gap = size.width * 0.055;
    final barWidth = (size.width - (gap * (barCount - 1))) / barCount;
    final phase = progress * math.pi * 2;

    for (var i = 0; i < barCount; i++) {
      final wave = 0.5 + (math.sin(phase + (i * 0.68)) * 0.5);
      final height = 7 + (wave * (size.height - 8));
      final left = i * (barWidth + gap);
      final top = (size.height - height) / 2;
      final color = Color.lerp(
        AppColors.white.withValues(alpha: 0.36),
        const Color(0xFF30D86A).withValues(alpha: 0.9),
        wave,
      )!;

      final paint = Paint()..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, height),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LoadingMeterPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
