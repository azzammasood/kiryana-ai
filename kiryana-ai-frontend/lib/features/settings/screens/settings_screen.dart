import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../dashboard/widgets/custom_bottom_nav.dart';
import '../../../../routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/profile_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/language_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final int _currentIndex = 3;
  bool _isWhatsAppEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isWhatsAppEnabled = prefs.getBool('whatsapp') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.logs);
        break;
      case 2:
        context.go(AppRoutes.insights);
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= AppSpacing.mobileBreakpoint;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : AppColors.secondary,
      body: Column(
        children: [
          _buildAppBar(isUrdu),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? AppSpacing.maxContentWidth : double.infinity,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _buildProfileCard(isUrdu),
                    const SizedBox(height: AppSpacing.md),
                    _buildSettingsList(isUrdu),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : CustomBottomNav(currentIndex: _currentIndex, onTap: _onNavTap),
    );
  }

  Widget _buildAppBar(bool isUrdu) {
    final profile = ref.watch(profileProvider);
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Image.asset(
              'assets/images/topbar-logo.png',
              width: 36,
              height: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    if (isUrdu)
                      const TextSpan(
                        text: 'ترتیبات ',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    TextSpan(
                      text: isUrdu ? '(Settings)' : 'Settings',
                      style: GoogleFonts.inter(
                        fontSize: isUrdu ? 14 : 19,
                        fontWeight: isUrdu ? FontWeight.w600 : FontWeight.w800,
                        color: isUrdu ? AppColors.white.withValues(alpha: 0.8) : AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.white.withValues(alpha: 0.2),
              backgroundImage: profile.profilePicPath != null
                  ? (kIsWeb 
                      ? NetworkImage(profile.profilePicPath!) 
                      : FileImage(File(profile.profilePicPath!)) as ImageProvider)
                  : null,
              child: profile.profilePicPath == null
                  ? const Icon(Icons.person_rounded, color: AppColors.white, size: 20)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isUrdu) {
    final profile = ref.watch(profileProvider);
    return GestureDetector(
      onTap: () => context.push(AppRoutes.profileEdit),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              // Info on Left (Fixed sequence)
              Expanded(
                child: Column(
                  crossAxisAlignment: isUrdu ? CrossAxisAlignment.start : CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: isUrdu
                        ? const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)
                        : GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'KiryanaAI Premium',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Profile Pic on Right (Fixed sequence)
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.secondary,
                backgroundImage: profile.profilePicPath != null
                    ? (kIsWeb 
                        ? NetworkImage(profile.profilePicPath!) 
                        : FileImage(File(profile.profilePicPath!)) as ImageProvider)
                    : null,
                child: profile.profilePicPath == null
                    ? Icon(Icons.person_rounded, size: 40, color: AppColors.primary.withValues(alpha: 0.5))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(bool isUrdu) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingRow(
            isUrdu: isUrdu,
            titleUrdu: 'فون نمبر تبدیل کریں',
            titleEnglish: 'Change Phone Number',
            icon: Icons.phone_android_rounded,
            showArrow: true,
            onTap: () => context.push(AppRoutes.changePhone),
          ),
          _buildDivider(),
          _buildSettingRow(
            isUrdu: isUrdu,
            titleUrdu: 'زبان',
            titleEnglish: 'Language',
            subtitleUrdu: 'اردو / English',
            subtitleEnglish: 'English / Urdu',
            icon: Icons.language_rounded,
            customTrailing: _buildLanguageToggle(),
          ),
          _buildDivider(),
          _buildSettingRow(
            isUrdu: isUrdu,
            titleUrdu: 'واٹس ایپ رپورٹ',
            titleEnglish: 'WhatsApp Report',
            subtitleUrdu: 'روزانہ کی رپورٹ موصول کریں',
            subtitleEnglish: 'Receive daily reports',
            icon: Icons.chat_rounded,
            customTrailing: Switch(
              value: _isWhatsAppEnabled,
              onChanged: (val) {
                setState(() => _isWhatsAppEnabled = val);
                _saveSetting('whatsapp', val);
              },
              activeTrackColor: const Color(0xFF1B6D24),
              activeThumbColor: AppColors.white,
              inactiveTrackColor: AppColors.border,
              inactiveThumbColor: AppColors.white,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              thumbIcon: WidgetStateProperty.all(const Icon(Icons.circle, color: Colors.transparent)),
            ),
          ),
          _buildDivider(),
          _buildSettingRow(
            isUrdu: isUrdu,
            titleUrdu: 'ڈارک موڈ',
            titleEnglish: 'Dark Mode',
            subtitleUrdu: 'ایپ کی تھیم تبدیل کریں',
            subtitleEnglish: 'Change app theme',
            icon: Icons.dark_mode_rounded,
            customTrailing: Switch(
              value: ref.watch(themeProvider) == ThemeMode.dark,
              onChanged: (val) {
                ref.read(themeProvider.notifier).toggleTheme(val);
              },
              activeTrackColor: const Color(0xFF1B6D24),
              activeThumbColor: AppColors.white,
              inactiveTrackColor: AppColors.border,
              inactiveThumbColor: AppColors.white,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              thumbIcon: WidgetStateProperty.all(const Icon(Icons.circle, color: Colors.transparent)),
            ),
          ),
          _buildDivider(),
          _buildSettingRow(
            isUrdu: isUrdu,
            titleUrdu: 'لاگ آؤٹ کریں',
            titleEnglish: 'Logout',
            subtitleEnglish: 'Sign Out',
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            iconBgColor: AppColors.error.withValues(alpha: 0.1),
            textColor: AppColors.error,
            showArrow: true,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('is_logged_in');
              if (mounted) context.go(AppRoutes.login);
            },
          ),
          _buildDivider(),
          _buildSettingRow(
            isUrdu: isUrdu,
            titleUrdu: 'ڈیٹا صاف کریں',
            titleEnglish: 'Clear Data',
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.error,
            iconBgColor: AppColors.error.withValues(alpha: 0.1),
            textColor: AppColors.error,
            showArrow: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required bool isUrdu,
    required String titleUrdu,
    required String titleEnglish,
    String? subtitleUrdu,
    String? subtitleEnglish,
    required IconData icon,
    Color? iconColor,
    Color? iconBgColor,
    Color? textColor,
    bool showArrow = false,
    Widget? customTrailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              // Icon on Left
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor ?? AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              
              // Text in Middle
              Expanded(
                child: Column(
                  crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUrdu ? titleUrdu : titleEnglish,
                      style: isUrdu 
                        ? TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor ?? AppColors.textPrimary)
                        : GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textColor ?? AppColors.textPrimary),
                    ),
                    if (isUrdu ? subtitleUrdu != null : subtitleEnglish != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        (isUrdu ? subtitleUrdu : subtitleEnglish)!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Trailing on Right
              if (customTrailing != null)
                customTrailing
              else if (showArrow)
                const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 24)
              else
                const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildLanguageToggle() {
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (isUrdu) {
                ref.read(languageProvider.notifier).setLanguage('en');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: !isUrdu ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'EN',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: !isUrdu ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (!isUrdu) {
                ref.read(languageProvider.notifier).setLanguage('ur');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isUrdu ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'اردو',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isUrdu ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
