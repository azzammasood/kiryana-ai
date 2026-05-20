import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/api_service.dart';
import '../../logs/providers/transaction_provider.dart';
import '../../settings/providers/profile_provider.dart';
import '../../../routes/app_router.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _controllers.map((controller) => controller.text).join();
    if (otp.length != 4) {
      setState(() => _error = 'Enter the 4 digit OTP');
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingUserId = prefs.getInt('pending_user_id');
      final pendingPhone = prefs.getString('pending_phone_number');
      if (pendingUserId == null || pendingPhone == null) {
        throw Exception('Phone verification expired. Please login again.');
      }

      await ApiService().setCurrentUser(pendingUserId, pendingPhone);
      await prefs.setBool('is_logged_in', true);
      final authMode = prefs.getString('pending_auth_mode') ?? 'login';
      await prefs.remove('pending_user_id');
      await prefs.remove('pending_phone_number');
      await prefs.remove('pending_auth_mode');
      await ref
          .read(profileProvider.notifier)
          .loadProfileForPhone(pendingPhone);
      ref.invalidate(transactionsProvider);

      if (!mounted) return;
      if (authMode == 'signup') {
        context.go(AppRoutes.profileSetup);
      } else {
        context.go(AppRoutes.dashboard);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = ApiService().errorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= AppSpacing.mobileBreakpoint;
    final isUrdu = ref.watch(languageProvider).languageCode == 'ur';

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 12,
              left: 14,
              right: 14,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go(AppRoutes.login),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.white),
                ),
                Image.asset('assets/images/topbar-logo.png',
                    width: 36, height: 36),
                const SizedBox(width: 10),
                Text(
                  isUrdu ? 'OTP' : 'Verify OTP',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        isWide ? AppSpacing.maxContentWidth : double.infinity,
                  ),
                  child: Container(
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
                        Image.asset('assets/images/login-logo.png',
                            width: 112, height: 112, fit: BoxFit.contain),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          isUrdu ? 'OTP Darj Karen' : 'Enter OTP',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const SizedBox(height: AppSpacing.xl),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (index) => Container(
                              width: 58,
                              height: 58,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(1),
                                ],
                                onChanged: (value) => _onChanged(value, index),
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                cursorColor: AppColors.primary,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.secondary,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verify,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.actionGreen,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(
                                    isUrdu ? 'Verify Karen' : 'Verify',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
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
          ),
        ],
      ),
    );
  }
}
