import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';
import '../../../../core/widgets/app_widgets.dart';

class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool _otpSent = false;
  bool _isLoading = false;

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

  void _sendOtp() async {
    final isUrdu = ref.read(languageProvider).languageCode == 'ur';
    final phone = _phoneController.text.trim();

    // Regex for +923xxxxxxxxx or 03xxxxxxxxx (same as login)
    final RegExp phoneRegExp = RegExp(r'^(?:\+92|0)3\d{9}$');

    if (!phoneRegExp.hasMatch(phone)) {
      AppToast.show(
        context,
        isUrdu
            ? 'براہ کرم درست فون نمبر درج کریں'
            : 'Please enter a valid phone number',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _otpSent = true;
      });
      AppToast.show(
        context,
        isUrdu ? 'OTP sent successfully!' : 'OTP sent successfully!',
      );
    }
  }

  void _verifyOtp() async {
    final isUrdu = ref.read(languageProvider).languageCode == 'ur';
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 4) {
      AppToast.show(
        context,
        isUrdu ? 'براہ کرم مکمل OTP درج کریں' : 'Please enter complete OTP',
        isError: true,
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      AppToast.show(
        context,
        isUrdu
            ? 'فون نمبر کامیابی کے ساتھ اپ ڈیٹ ہو گیا!'
            : 'Phone number updated successfully!',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back_rounded, color: AppColors.white),
              onPressed: () => context.pop(),
            ),
            title: Text(
              isUrdu
                  ? 'فون نمبر تبدیل کریں (Change Phone)'
                  : 'Change Phone Number',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Icon(Icons.phone_android_rounded,
                size: 80, color: AppColors.primary.withValues(alpha: 0.8)),
            const SizedBox(height: AppSpacing.xl),

            // Phone Field
            Align(
              alignment: isUrdu ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                isUrdu ? 'نیا فون نمبر (New Phone Number)' : 'New Phone Number',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
                decoration: BoxDecoration(
                  color: _otpSent
                      ? AppColors.border.withValues(alpha: 0.3)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_otpSent,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: '+92 300 1234567',
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textSecondary.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    prefixIcon:
                        const Icon(Icons.phone, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),

            if (_otpSent) ...[
              const SizedBox(height: AppSpacing.xl),
              Align(
                alignment:
                    isUrdu ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  isUrdu ? 'او ٹی پی (OTP)' : 'OTP',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    return SizedBox(
                      width: 56,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            hintText: '${index + 1}',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.4),
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
            ],

            const SizedBox(height: AppSpacing.xxl),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionGreen,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2))
                    : Text(
                        _otpSent
                            ? (isUrdu ? 'تصدیق کریں (Verify)' : 'Verify')
                            : (isUrdu
                                ? 'او ٹی پی بھیجیں (Send OTP)'
                                : 'Send OTP'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
