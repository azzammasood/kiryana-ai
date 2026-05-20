import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/language_provider.dart';
import '../../../routes/app_router.dart';

enum AuthMode { login, signUp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  AuthMode _mode = AuthMode.login;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final phone = _phoneController.text.trim();
    final phoneRegExp = RegExp(r'^(?:\+92|0)3\d{9}$');
    if (!phoneRegExp.hasMatch(phone)) {
      setState(() => _error = 'Please enter a valid Pakistani phone number');
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    final isSignUp = _mode == AuthMode.signUp;

    try {
      final user = await ApiService().createUser(
        phone,
        name: isSignUp ? 'Dukandaar' : 'Kiryana Owner',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'pending_auth_mode',
        isSignUp ? 'signup' : 'login',
      );
      await prefs.setInt('pending_user_id', user['id'] as int);
      await prefs.setString('pending_phone_number', phone);
      if (!mounted) return;
      context.go(AppRoutes.otp);
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

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= AppSpacing.mobileBreakpoint;
    final isUrdu = ref.watch(languageProvider).languageCode == 'ur';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.secondary,
        body: Column(
          children: [
            _Header(
              title: isUrdu ? 'اکاؤنٹ' : 'Account',
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide
                          ? AppSpacing.maxContentWidth
                          : double.infinity,
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
                              width: 132, height: 132, fit: BoxFit.contain),
                          const SizedBox(height: AppSpacing.lg),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Kiryana',
                                  style: GoogleFonts.inter(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: 'AI',
                                  style: GoogleFonts.inter(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.actionGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            isUrdu
                                ? 'فون نمبر درج کریں، پھر لاگ اِن یا سائن اَپ'
                                : 'Enter your phone number, then log in or sign up',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _AuthModeToggle(
                            mode: _mode,
                            isUrdu: isUrdu,
                            onChanged: (m) => setState(() => _mode = m),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isUrdu ? 'فون نمبر' : 'Phone number',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              hintText: '03001234567',
                              hintStyle:
                                  const TextStyle(color: AppColors.textHint),
                              filled: true,
                              fillColor: AppColors.secondary,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _continue,
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
                                      _mode == AuthMode.signUp
                                          ? (isUrdu
                                              ? 'سائن اَپ جاری رکھیں'
                                              : 'Continue with Sign up')
                                          : (isUrdu
                                              ? 'لاگ اِن جاری رکھیں'
                                              : 'Continue with Log in'),
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
      ),
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  final AuthMode mode;
  final bool isUrdu;
  final ValueChanged<AuthMode> onChanged;

  const _AuthModeToggle({
    required this.mode,
    required this.isUrdu,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeChip(
              label: isUrdu ? 'لاگ اِن' : 'Log in',
              selected: mode == AuthMode.login,
              onTap: () => onChanged(AuthMode.login),
            ),
          ),
          Expanded(
            child: _ModeChip(
              label: isUrdu ? 'سائن اَپ' : 'Sign up',
              selected: mode == AuthMode.signUp,
              onTap: () => onChanged(AuthMode.signUp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;

  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 12,
        left: 14,
        right: 14,
      ),
      child: Row(
        children: [
          Image.asset('assets/images/topbar-logo.png', width: 36, height: 36),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const Spacer(),
          const Icon(Icons.lock_outline_rounded,
              color: AppColors.white, size: 18),
        ],
      ),
    );
  }
}
