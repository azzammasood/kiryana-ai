import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../dashboard/widgets/custom_bottom_nav.dart';
import '../../../../routes/app_router.dart';
import 'package:kiryana_ai/features/logs/providers/transaction_provider.dart';
import '../../settings/providers/profile_provider.dart';
import '../../../core/providers/language_provider.dart';



// ── Dynamic Data Models ───────────────────────────────────────────────────────

class TopSellingItem {
  final String nameUrdu;
  final String nameEnglish;
  final String qtyUrdu;
  final String qtyEnglish;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const TopSellingItem({
    required this.nameUrdu,
    required this.nameEnglish,
    required this.qtyUrdu,
    required this.qtyEnglish,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class AiSuggestion {
  final String textUrdu;
  final String textEnglish;
  final IconData icon;
  final Color iconColor;

  const AiSuggestion({
    required this.textUrdu,
    required this.textEnglish,
    required this.icon,
    required this.iconColor,
  });
}

// ── Static AI Suggestions (will be dynamic after backend) ─────────────────────

const List<AiSuggestion> _suggestions = [
  AiSuggestion(
    textUrdu: 'دودھ کی سپلائی ہفتہ کو بڑھا دیں۔',
    textEnglish: 'Increase milk supply on Saturday.',
    icon: Icons.trending_up_rounded,
    iconColor: Color(0xFF1B6D24),
  ),
  AiSuggestion(
    textUrdu: 'چینی کی قیمت چیک کریں۔',
    textEnglish: 'Check the price of sugar.',
    icon: Icons.warning_amber_rounded,
    iconColor: Color(0xFFF57C00),
  ),
];

// ── Static Top Items (will be dynamic after backend) ──────────────────────────

const List<TopSellingItem> _staticTopItems = [
  TopSellingItem(
    nameUrdu: 'دودھ',
    nameEnglish: 'Milk (Olpers)',
    qtyUrdu: '120 لیٹر',
    qtyEnglish: '120 Liters',
    icon: Icons.water_drop_rounded,
    iconColor: Color(0xFF1B6D24),
    iconBg: Color(0xFFE8F5E9),
  ),
  TopSellingItem(
    nameUrdu: 'انڈے',
    nameEnglish: 'Eggs (Dozen)',
    qtyUrdu: '45 درجن',
    qtyEnglish: '45 Dozen',
    icon: Icons.egg_outlined,
    iconColor: Color(0xFF1B6D24),
    iconBg: Color(0xFFE8F5E9),
  ),
  TopSellingItem(
    nameUrdu: 'ڈبل روٹی',
    nameEnglish: 'Bread (Dawn)',
    qtyUrdu: '30 پیکٹ',
    qtyEnglish: '30 Packets',
    icon: Icons.inventory_2_rounded,
    iconColor: Color(0xFFD32F2F),
    iconBg: Color(0xFFFFEBEE),
  ),
];


class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  final int _currentIndex = 2;

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.go(AppRoutes.logs);
      case 3:
        context.go(AppRoutes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= AppSpacing.mobileBreakpoint;
    final weeklyIncome = ref.watch(weeklySalesProvider);
    final weeklyExpense = ref.watch(weeklyExpensesProvider);
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : const Color(0xFFE8EFF2),
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? AppSpacing.maxContentWidth : double.infinity,
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _buildReportHeader(isUrdu),
                    const SizedBox(height: 16),
                    _buildWeeklySummary(
                      isUrdu: isUrdu,
                      income: weeklyIncome,
                      expenses: weeklyExpense,
                      currencyFormat: currencyFormat,
                    ),
                    const SizedBox(height: 20),
                    _buildTopSellingSection(isUrdu, _staticTopItems),
                    const SizedBox(height: 20),
                    _buildAiSuggestions(isUrdu, _suggestions),
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

  // ── AppBar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
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
                    TextSpan(
                      text: 'Kiryana ',
                      style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.white),
                    ),
                    const TextSpan(
                      text: 'AI',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF4CAF50)),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.go(AppRoutes.settings),
              child: CircleAvatar(
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
            ),
          ],
        ),
      ),
    );
  }

  // ── Report Header ───────────────────────────────────────────────────────────
  Widget _buildReportHeader(bool isUrdu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: AppColors.white.withValues(alpha: 0.3), width: 0.5) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/whatsapp-icon.png',
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isUrdu ? 'واٹس ایپ پہ بھیجو' : 'Share on WhatsApp',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          isUrdu ? 'ہفتہ وار رپورٹ' : 'Weekly Report',
          style: isUrdu 
            ? TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: isDark ? AppColors.white : AppColors.textPrimary)
            : GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: isDark ? AppColors.white : AppColors.textPrimary),
        ),
      ],
    );
  }

  // ── Weekly Summary (dynamic bars) ───────────────────────────────────────────
  Widget _buildWeeklySummary({
    required bool isUrdu,
    required int income,
    required int expenses,
    required NumberFormat currencyFormat,
  }) {
    final maxVal = income > expenses ? income : expenses;
    // Proportional bar heights (max 100px)
    final incomeBarH = maxVal == 0 ? 10.0 : (income / maxVal) * 100;
    final expenseBarH = maxVal == 0 ? 10.0 : (expenses / maxVal) * 100;

    return Container(
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
      child: Column(
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: isUrdu ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
              children: [
                Text(
                  'Weekly Summary',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                if (isUrdu)
                  const Text(
                    'خلاصہ',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bar chart - Forced LTR to keep Expenses left and Income right
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Expenses bar — LEFT
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Rs. ${currencyFormat.format(expenses)}',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.error),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 90,
                             height: expenseBarH,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD32F2F),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isUrdu)
                          const Text(
                            'اخراجات',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        if (isUrdu) const SizedBox(height: 2),
                        Text('Expenses', style: GoogleFonts.inter(fontSize: isUrdu ? 12 : 14, fontWeight: isUrdu ? FontWeight.w500 : FontWeight.w700, color: isUrdu ? AppColors.textSecondary : AppColors.textPrimary)),
                      ],
                    ),
                  ),

                  // Income bar — RIGHT
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Rs. ${currencyFormat.format(income)}',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.actionGreen),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 90,
                            height: incomeBarH,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1B6D24),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isUrdu)
                          const Text(
                            'آمدنی',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        if (isUrdu) const SizedBox(height: 2),
                        Text('Income', style: GoogleFonts.inter(fontSize: isUrdu ? 12 : 14, fontWeight: isUrdu ? FontWeight.w500 : FontWeight.w700, color: isUrdu ? AppColors.textSecondary : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Selling Items ───────────────────────────────────────────────────────
  Widget _buildTopSellingSection(bool isUrdu, List<TopSellingItem> topItems) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
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
          Row(
            mainAxisAlignment: isUrdu ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUrdu)
                const Icon(
                  Icons.star_border_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              if (!isUrdu) const SizedBox(width: 6),
              Text(
                isUrdu ? 'ٹاپ سیلنگ آئٹمز' : 'Top Selling Items',
                style: isUrdu
                  ? const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)
                  : GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              if (isUrdu) const SizedBox(width: 6),
              if (isUrdu)
                const Icon(
                  Icons.star_border_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...topItems.asMap().entries.map((entry) {
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildTopItemRow(isUrdu, item),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopItemRow(bool isUrdu, TopSellingItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5E5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (!isUrdu)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: item.iconBg, shape: BoxShape.circle),
              child: Icon(item.icon, size: 18, color: item.iconColor),
            ),
          if (!isUrdu) const SizedBox(width: 10),
          if (!isUrdu)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameEnglish,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    item.qtyEnglish,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          if (isUrdu)
            Text(
              item.qtyUrdu,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          if (isUrdu) const Spacer(),
          if (isUrdu)
            Text(
              item.nameUrdu,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          if (isUrdu) const SizedBox(width: 4),
          if (isUrdu)
            Text(
              item.nameEnglish,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
            ),
          if (isUrdu) const SizedBox(width: 10),
          if (isUrdu)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: item.iconBg, shape: BoxShape.circle),
              child: Icon(item.icon, size: 18, color: item.iconColor),
            ),
        ],
      ),
    );
  }

  // ── AI Suggestions ──────────────────────────────────────────────────────────
  Widget _buildAiSuggestions(bool isUrdu, List<AiSuggestion> suggestions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryLight : AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppColors.white.withValues(alpha: 0.4), width: 1.2) : null,
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      child: Column(
        crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: isUrdu ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isUrdu)
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.white, size: 18),
                  ),
                if (!isUrdu) const SizedBox(width: 8),
                Text(
                  isUrdu ? 'تجاویز AI' : 'AI Suggestions',
                  style: isUrdu
                    ? const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.white)
                    : GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.white),
                ),
                if (isUrdu) const SizedBox(width: 8),
                if (isUrdu)
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.white, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.map((s) => _buildSuggestionRow(isUrdu, s)),
        ],
      ),
    );
  }

  Widget _buildSuggestionRow(bool isUrdu, AiSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFF2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (!isUrdu) Icon(suggestion.icon, size: 22, color: suggestion.iconColor),
          if (!isUrdu) const SizedBox(width: 10),
          Expanded(
            child: Text(
              isUrdu ? suggestion.textUrdu : suggestion.textEnglish,
              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isUrdu ? TextAlign.right : TextAlign.left,
              style: isUrdu
                ? const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)
                : GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          if (isUrdu) const SizedBox(width: 10),
          if (isUrdu) Icon(suggestion.icon, size: 22, color: suggestion.iconColor),
        ],
      ),
    );
  }
}
