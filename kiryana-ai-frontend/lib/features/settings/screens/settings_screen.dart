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
import '../../../../core/services/api_service.dart';
import '../../logs/providers/transaction_provider.dart';
import '../../../core/widgets/animated_topbar_logo.dart';
import '../widgets/whatsapp_schedule_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final int _currentIndex = 3;
  bool _isWhatsAppEnabled = true;
  String _notificationDay = 'Sunday';
  String _notificationTime = '10:00';

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
    try {
      final userId = await ApiService().currentUserId();
      final remote = await ApiService().getNotificationSettings(userId);
      if (!mounted) return;
      setState(() {
        _notificationDay =
            (remote['notification_day'] ?? _notificationDay).toString();
        _notificationTime =
            (remote['notification_time'] ?? _notificationTime).toString();
        _isWhatsAppEnabled = remote['notifications_enabled'] == true ||
            (remote['notifications_enabled'] == null && _isWhatsAppEnabled);
      });
      await prefs.setBool('whatsapp', _isWhatsAppEnabled);
    } catch (_) {}
  }

  String _whatsappScheduleSubtitle(bool isUrdu) {
    if (!_isWhatsAppEnabled) {
      return isUrdu ? 'رپورٹ بند ہے' : 'Reports off';
    }
    final shortDay = _notificationDay.length >= 3
        ? _notificationDay.substring(0, 3)
        : _notificationDay;
    return isUrdu
        ? '$shortDay ${_notificationTime} بجے'
        : 'Every $shortDay at $_notificationTime';
  }

  Future<void> _openWhatsAppScheduler(bool isUrdu) async {
    final result = await showWhatsAppScheduleSheet(
      context: context,
      isUrdu: isUrdu,
      initialDay: _notificationDay,
      initialTime: _notificationTime,
      notificationsEnabled: _isWhatsAppEnabled,
    );
    if (result == null || !mounted) return;
    setState(() {
      _notificationDay = result.day;
      _notificationTime = result.time;
      _isWhatsAppEnabled = result.enabled;
    });
    await _saveSetting('whatsapp', result.enabled);
    try {
      final userId = await ApiService().currentUserId();
      await ApiService().updateNotificationSettings(
        userId: userId,
        notificationDay: result.day,
        notificationTime: result.time,
        notificationsEnabled: result.enabled,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService().errorMessage(error))),
        );
      }
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _showSubscriptionDialog(bool isUrdu) async {
    final profile = ref.read(profileProvider);
    final isPremium = profile.isPremium;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isUrdu ? 'سبسکرپشن' : 'Manage Subscription',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          content: Text(
            isPremium
                ? (isUrdu
                    ? 'Premium plan active hai. Kya aap free plan par wapas jana chahte hain?'
                    : 'You are on the Premium plan. Do you want to unsubscribe and switch back to Free?')
                : (isUrdu
                    ? 'Free plan active hai. Premium se unlimited AI sessions unlock karein.'
                    : 'You are on the Free plan. Upgrade to Premium for unlimited AI sessions.'),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                isUrdu ? 'منسوخ' : 'Cancel',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(profileProvider.notifier).setPlan(
                      isPremium ? 'free' : 'premium',
                    );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isPremium
                            ? (isUrdu
                                ? 'Free plan par switch ho gaya'
                                : 'Switched to Free plan')
                            : (isUrdu
                                ? 'Premium plan activate ho gaya'
                                : 'Premium plan activated'),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPremium ? AppColors.error : const Color(0xFFC99922),
                foregroundColor: AppColors.white,
              ),
              child: Text(
                isPremium
                    ? (isUrdu ? 'Unsubscribe' : 'Unsubscribe')
                    : (isUrdu ? 'Upgrade' : 'Upgrade to Premium'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
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
    final isWide =
        MediaQuery.of(context).size.width >= AppSpacing.mobileBreakpoint;
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
                  maxWidth:
                      isWide ? AppSpacing.maxContentWidth : double.infinity,
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
            const AnimatedTopBarLogo(size: 36),
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
                    if (!isUrdu)
                      TextSpan(
                        text: 'Settings',
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
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
                      : FileImage(File(profile.profilePicPath!))
                          as ImageProvider)
                  : null,
              child: profile.profilePicPath == null
                  ? const Icon(Icons.person_rounded,
                      color: AppColors.white, size: 20)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isUrdu) {
    final profile = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = profile.isPremium
        ? const Color(0xFFFFF4CF)
        : (isDark ? AppColors.darkCard : AppColors.white);
    final primaryTextColor = profile.isPremium
        ? const Color(0xFF5C4100)
        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);
    final secondaryTextColor = profile.isPremium
        ? const Color(0xFF8A6500)
        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);
    final iconBgColor = profile.isPremium
        ? const Color(0xFFFFD76A)
        : (isDark ? AppColors.primaryLight : AppColors.secondary);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.04);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.profileEdit),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: profile.isPremium
              ? Border.all(color: const Color(0xFFC99922), width: 1.5)
              : isDark
                  ? Border.all(
                      color: AppColors.darkBorder.withValues(alpha: 0.55))
                  : null,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              // Info on Left (Fixed sequence)
              Expanded(
                child: Column(
                  crossAxisAlignment: isUrdu
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: isUrdu
                          ? TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor)
                          : GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.isPremium
                          ? 'KiryanaAI Premium'
                          : 'KiryanaAI Free',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                      ),
                    ),
                    if (profile.storeName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.storeName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Profile Pic on Right (Fixed sequence)
              CircleAvatar(
                radius: 32,
                backgroundColor: iconBgColor,
                backgroundImage: profile.profilePicPath != null
                    ? (kIsWeb
                        ? NetworkImage(profile.profilePicPath!)
                        : FileImage(File(profile.profilePicPath!))
                            as ImageProvider)
                    : null,
                child: profile.profilePicPath == null
                    ? Icon(Icons.person_rounded,
                        size: 40,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.primary.withValues(alpha: 0.5))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(bool isUrdu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.white;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.04);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDark
            ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.55))
            : null,
      ),
      child: Column(
        children: [
          _buildSettingRow(
            isUrdu: isUrdu,
            titleUrdu: 'Subscription',
            titleEnglish: 'Manage Subscription',
            subtitleUrdu: ref.watch(profileProvider).isPremium
                ? 'Premium plan active'
                : 'Free plan active',
            subtitleEnglish: ref.watch(profileProvider).isPremium
                ? 'Premium plan active'
                : 'Free plan active',
            icon: Icons.workspace_premium_rounded,
            iconColor: const Color(0xFFC99922),
            iconBgColor: const Color(0xFFFFF4CF),
            showArrow: true,
            onTap: () => _showSubscriptionDialog(isUrdu),
          ),
          _buildDivider(),
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
            subtitleUrdu: 'اردو',
            subtitleEnglish: 'English / Urdu',
            icon: Icons.language_rounded,
            customTrailing: _buildLanguageToggle(),
          ),
          _buildDivider(),
          _buildWhatsAppScheduleRow(isUrdu),
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
              thumbIcon: WidgetStateProperty.all(
                  const Icon(Icons.circle, color: Colors.transparent)),
            ),
          ),
          _buildDivider(),
          _buildSettingRow(
            isUrdu: isUrdu,
            titleUrdu: 'ایپ کے بارے میں',
            titleEnglish: 'About',
            subtitleUrdu: 'ٹیم اور چیلنج کی تفصیل',
            subtitleEnglish: 'Team and challenge details',
            icon: Icons.info_outline_rounded,
            showArrow: true,
            onTap: () => _showAboutDialog(isUrdu),
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
              await ApiService().clearCurrentUser();
              ref.invalidate(transactionsProvider);
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

  Widget _buildWhatsAppScheduleRow(bool isUrdu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openWhatsAppScheduler(isUrdu),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F8EE),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/images/whatsapp-icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUrdu ? 'واٹس ایپ رپورٹ' : 'WhatsApp Report',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _whatsappScheduleSubtitle(isUrdu),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isUrdu
                                  ? 'شیڈول تبدیل کرنے کے لیے ٹیپ کریں'
                                  : 'Tap to set day & time',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Switch(
              value: _isWhatsAppEnabled,
              onChanged: (val) async {
                setState(() => _isWhatsAppEnabled = val);
                await _saveSetting('whatsapp', val);
                try {
                  final userId = await ApiService().currentUserId();
                  await ApiService().updateNotificationSettings(
                    userId: userId,
                    notificationsEnabled: val,
                  );
                } catch (_) {}
              },
              activeTrackColor: const Color(0xFF25D366),
              activeThumbColor: AppColors.white,
              inactiveTrackColor: AppColors.border,
              inactiveThumbColor: AppColors.white,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(bool isUrdu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
        title: Text(
          isUrdu ? 'Kiryana AI' : 'About Kiryana AI',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Developed as a prototype for Challenge 1: Autonomous Content-to-Action Agent.',
                style: GoogleFonts.inter(height: 1.45),
              ),
              const SizedBox(height: 12),
              Text(
                'Kiryana AI helps Pakistani kiryana store owners log sales and expenses by voice, '
                'generates weekly business insights, learns from feedback, and turns shop data into '
                'actionable recommendations.',
                style: GoogleFonts.inter(height: 1.45),
              ),
              const SizedBox(height: 16),
              Text(
                'Team',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...[
                'Ahmad Uzzam Masood — Backend Developer',
                'Muhammad Usman — Frontend Developer',
                'Muhammad Abdul Majeed — AI Developer',
                'Esha Shabbir — AI Developer',
                'Muhammad Jamil Mughal — UI/UX Designer',
              ].map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line, style: GoogleFonts.inter(height: 1.35)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final defaultIconBgColor = isDark
        ? AppColors.primaryLight.withValues(alpha: 0.78)
        : AppColors.secondary;
    final defaultIconColor =
        isDark ? AppColors.darkTextPrimary : AppColors.primary;
    final resolvedTextColor = textColor == AppColors.error && isDark
        ? AppColors.errorReadable
        : textColor;
    final resolvedIconColor = iconColor == AppColors.error && isDark
        ? AppColors.errorReadable
        : iconColor;

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
                  color: iconBgColor ?? defaultIconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: resolvedIconColor ?? defaultIconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),

              // Text in Middle
              Expanded(
                child: Column(
                  crossAxisAlignment: isUrdu
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUrdu ? titleUrdu : titleEnglish,
                      style: isUrdu
                          ? TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: resolvedTextColor ?? primaryTextColor)
                          : GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: resolvedTextColor ?? primaryTextColor),
                    ),
                    if (isUrdu
                        ? subtitleUrdu != null
                        : subtitleEnglish != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        (isUrdu ? subtitleUrdu : subtitleEnglish)!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: secondaryTextColor,
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
                Icon(Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textHint,
                    size: 24)
              else
                const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? AppColors.darkBorder.withValues(alpha: 0.65)
          : AppColors.border,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildLanguageToggle() {
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.42)
            : AppColors.secondary,
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
                  color: !isUrdu
                      ? AppColors.white
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
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
                  color: isUrdu
                      ? AppColors.white
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
