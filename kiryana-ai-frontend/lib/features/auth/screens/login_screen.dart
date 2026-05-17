import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  bool _isOtpSent = false;
  String? _phoneError;
  String? _otpError;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onNextPressed() {
    if (!_isOtpSent) {
      // Validate Phone Number
      final phone = _phoneController.text.trim();
      // Regex for +923xxxxxxxxx or 03xxxxxxxxx
      final RegExp phoneRegExp = RegExp(r'^(?:\+92|0)3\d{9}$');
      
      if (!phoneRegExp.hasMatch(phone)) {
        setState(() {
          _phoneError = 'براہ کرم درست فون نمبر درج کریں'; // Please enter a valid phone number
        });
        return;
      }
      
      // Simulate sending OTP
      setState(() {
        _phoneError = null;
        _isOtpSent = true;
      });
      
      // Auto-focus first OTP field
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } else {
      // Validate OTP
      String otp = _otpControllers.map((c) => c.text).join();
      if (otp.length < 4) {
        setState(() {
          _otpError = 'براہ کرم مکمل OTP درج کریں'; // Please enter complete OTP
        });
        return;
      }
      
      // Proceed to dashboard after OTP is entered
      setState(() {
        _otpError = null;
      });
      
      // Save login state
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('is_logged_in', true);
      });
      
      context.go('/dashboard');
    }
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader(bool isUrdu) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 12,
        left: 14,
        right: 14,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            // Badge icon
            Image.asset(
              'assets/images/topbar-logo.png',
              width: 36,
              height: 36,
            ),
            const SizedBox(width: 10),
    
            // Title
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Welcome Back',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  if (isUrdu) ...[
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'خوش آمدید',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    
            // Language Toggle? (Optional, but useful for login)
            const SizedBox(width: 10),
            const Icon(Icons.lock_outline_rounded, color: AppColors.white, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= AppSpacing.mobileBreakpoint;
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

    return Scaffold(
      backgroundColor: AppColors.secondary, // Light off-white background
      body: Column(
        children: [
          _buildHeader(isUrdu),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? AppSpacing.maxContentWidth : double.infinity,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.pagePadding),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: 40,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Logo Image Placeholder ───────────────────────────
                          _LogoPlaceholder(),
    
                          const SizedBox(height: AppSpacing.lg),
    
                          // ── "KiryanaAI" ──────────────────────────────────────
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Kiryana',
                                  style: GoogleFonts.inter(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'AI',
                                  style: GoogleFonts.inter(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.actionGreen,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
    
                          const SizedBox(height: AppSpacing.md),
    
                          // ── Urdu Tagline ─────────────────────────────────────
                          const Text(
                            AppStrings.loginTaglineUrdu,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              height: 1.6,
                            ),
                          ),
    
                          const SizedBox(height: 48),
    
                          // ── Phone Input Label ────────────────────────────────
                          Align(
                            alignment: isUrdu ? Alignment.centerRight : Alignment.centerLeft,
                            child: Text(
                              isUrdu ? AppStrings.enterPhoneUrdu : 'Enter Phone Number',
                              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
    
                          // ── Phone Input Field ────────────────────────────────
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                ),
                              ),
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                enabled: !_isOtpSent, // Disable if OTP sent
    
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: '+92 300 1234567',
                                  hintStyle: GoogleFonts.inter(
                                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
    
                          if (_phoneError != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: isUrdu ? Alignment.centerRight : Alignment.centerLeft,
                              child: Text(
                                _phoneError!,
                                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
    
                          const SizedBox(height: AppSpacing.sm),
    
                          // ── Helper Text ──────────────────────────────────────
                          Align(
                            alignment: isUrdu ? Alignment.centerRight : Alignment.centerLeft,
                            child: Text(
                              isUrdu ? AppStrings.weWillSendCodeUrdu : 'We will send you a verification code',
                              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
    
                          const SizedBox(height: AppSpacing.xl),
    
                          // ── Next Button ──────────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: _onNextPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.actionGreen,
                                foregroundColor: AppColors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                textDirection: TextDirection.ltr,
                                children: [
                                  Text(
                                    isUrdu ? AppStrings.goNextUrdu : 'Next',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Icon(Icons.arrow_forward_rounded, size: 22),
                                  ),
                                ],
                              ),
                            ),
                          ),
    
                          const SizedBox(height: 48),
    
                          // ── OTP Divider ──────────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                child: Text(
                                  isUrdu ? AppStrings.enterOtpUrdu : 'Enter OTP Code',
                                  textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
    
                          const SizedBox(height: AppSpacing.xl),
    
                          Directionality(
                            textDirection: TextDirection.ltr, // Keep OTP sequence fixed
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(4, (index) {
                                return SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _otpControllers[index],
                                      focusNode: _otpFocusNodes[index],
                                      enabled: _isOtpSent, // Only enabled if OTP sent
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        border: InputBorder.none,
                                        hintText: '${index + 1}',
                                        hintStyle: GoogleFonts.inter(
                                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty && index < 3) {
                                          _otpFocusNodes[index + 1].requestFocus();
                                        } else if (value.isEmpty && index > 0) {
                                          _otpFocusNodes[index - 1].requestFocus();
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
    
                          if (_otpError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _otpError!,
                              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.error,
                              ),
                            ),
                          ],
    
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo Placeholder ──────────────────────────────────────────────────────────
class _LogoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/login-logo.png',
      width: 140,
      height: 140,
      fit: BoxFit.contain,
    );
  }
}
