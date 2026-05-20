import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_thumb_button.dart';
import '../../dashboard/widgets/custom_bottom_nav.dart';
import '../../../../routes/app_router.dart';
import '../../settings/providers/profile_provider.dart';
import '../../../core/providers/latest_insight_provider.dart';
import '../../../core/widgets/animated_topbar_logo.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/recommendation_localization.dart';
import '../widgets/ask_ai_banner.dart';

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

const List<AiSuggestion> legacySuggestions = [
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

const List<TopSellingItem> legacyStaticTopItems = [
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
  final Map<String, bool> _recommendationVotes = {};

  Map<String, dynamic>? get _latestInsight =>
      ref.watch(latestInsightProvider).data;

  Future<void> _sendWhatsApp() async {
    try {
      final userId = await ApiService().currentUserId();
      final result = await ApiService().sendWhatsApp(userId);
      if (!mounted) return;
      AppToast.show(
          context,
          result['sent'] == true
              ? 'WhatsApp report bhej di gayi'
              : 'WhatsApp send fail ho gaya');
    } catch (error) {
      if (mounted) {
        AppToast.show(context, ApiService().errorMessage(error), isError: true);
      }
    }
  }

  String _feedbackKey(AiSuggestion suggestion) {
    return LocalizedRecommendation(
      textEnglish: suggestion.textEnglish,
      textUrdu: suggestion.textUrdu,
    ).feedbackKey;
  }

  void _submitRecommendationFeedback(String recommendation, bool accepted) {
    final insightId = (_latestInsight?['id'] as num?)?.toInt();
    if (insightId == null) return;
    if (_recommendationVotes.containsKey(recommendation)) return;

    setState(() {
      _recommendationVotes[recommendation] = accepted;
    });

    _persistRecommendationFeedback(
      insightId: insightId,
      recommendation: recommendation,
      accepted: accepted,
    );
  }

  Future<void> _persistRecommendationFeedback({
    required int insightId,
    required String recommendation,
    required bool accepted,
  }) async {
    try {
      final userId = await ApiService().currentUserId();
      await ApiService().submitRecommendationFeedback(
        userId: userId,
        insightId: insightId,
        recommendationText: recommendation,
        accepted: accepted,
      );
      final kpis = await ApiService().getAdaptationKpis(userId);
      if (!mounted) return;
      ref.read(latestInsightProvider.notifier).mergePatch({'kpis': kpis});
      final merged = ref.read(latestInsightProvider).data;
      if (merged != null) {
        await ApiService().persistInsightCache(userId, merged);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _recommendationVotes.remove(recommendation);
      });
      AppToast.show(context, ApiService().errorMessage(error), isError: true);
    }
  }

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
    final insightState = ref.watch(latestInsightProvider);
    final isLoadingInsight = insightState.showFullScreenLoader;
    final insightError = insightState.error;

    final isWide =
        MediaQuery.of(context).size.width >= AppSpacing.mobileBreakpoint;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

    final suggestions = _suggestionsFromInsight();

    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : const Color(0xFFE8EFF2),
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      isWide ? AppSpacing.maxContentWidth : double.infinity,
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _buildReportHeader(isUrdu),
                    const SizedBox(height: 20),
                    if (isLoadingInsight)
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                    else if (insightError != null)
                      _buildInsightError(isUrdu, insightError)
                    else ...[
                      AskAiBanner(isUrdu: isUrdu),
                      const SizedBox(height: 16),
                      _buildLearningBadge(isUrdu),
                      const SizedBox(height: 20),
                      _buildAiSuggestions(isUrdu, suggestions),
                    ],
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

  List<TopSellingItem> _topItemsFromInsight() {
    final sales = (_latestInsight?['top_items'] as List<dynamic>? ?? []);
    final expenses = (_latestInsight?['top_expenses'] as List<dynamic>? ?? []);
    final rows = sales.isNotEmpty ? sales : expenses;
    final isExpenseView = sales.isEmpty && expenses.isNotEmpty;
    return rows.take(3).map((item) {
      final row = Map<String, dynamic>.from(item as Map);
      final name = (row['item_name'] ?? 'Item').toString();
      final amount = ((row['amount'] as num?) ?? 0).round();
      return TopSellingItem(
        nameUrdu: name,
        nameEnglish: name,
        qtyUrdu: isExpenseView ? 'Kharcha Rs. $amount' : 'Rs. $amount',
        qtyEnglish: isExpenseView ? 'Expense Rs. $amount' : 'Rs. $amount',
        icon: isExpenseView ? Icons.receipt_long_rounded : Icons.inventory_2_rounded,
        iconColor: isExpenseView ? const Color(0xFFD32F2F) : AppColors.actionGreen,
        iconBg: isExpenseView ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
      );
    }).toList();
  }

  bool get _showingExpenseItems {
    final sales = (_latestInsight?['top_items'] as List<dynamic>? ?? []);
    final expenses = (_latestInsight?['top_expenses'] as List<dynamic>? ?? []);
    return sales.isEmpty && expenses.isNotEmpty;
  }

  List<AiSuggestion> _suggestionsFromInsight() {
    final rows = (_latestInsight?['recommendations'] as List<dynamic>? ?? []);
    final isUrdu = ref.read(languageProvider).languageCode == 'ur';
    final suggestions = <AiSuggestion>[];
    for (final item in rows.take(3)) {
      final localized = LocalizedRecommendation.fromDynamic(item);
      final display = localized.displayText(isUrdu);
      if (display.isEmpty) continue;
      suggestions.add(
        AiSuggestion(
          textUrdu: localized.textUrdu,
          textEnglish: localized.textEnglish,
          icon: Icons.trending_up_rounded,
          iconColor: AppColors.actionGreen,
        ),
      );
    }
    return suggestions;
  }

  Widget _buildInsightError(bool isUrdu, String message) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.errorReadable, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () =>
              ref.read(latestInsightProvider.notifier).reload(force: true),
          child: Text(isUrdu ? 'دوبارہ کوشش کریں' : 'Try Again'),
        ),
      ],
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
            const AnimatedTopBarLogo(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Kiryana ',
                      style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white),
                    ),
                    const TextSpan(
                      text: 'AI',
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4CAF50)),
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
                        : FileImage(File(profile.profilePicPath!))
                            as ImageProvider)
                    : null,
                child: profile.profilePicPath == null
                    ? const Icon(Icons.person_rounded,
                        color: AppColors.white, size: 20)
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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
      children: [
        GestureDetector(
          onTap: _sendWhatsApp,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              border: isDark
                  ? Border.all(
                      color: AppColors.white.withValues(alpha: 0.3), width: 0.5)
                  : null,
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
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Text(
          isUrdu ? 'ہفتہ وار رپورٹ' : 'Weekly Report',
          style: isUrdu
              ? TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.white : AppColors.textPrimary)
              : GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.white : AppColors.textPrimary),
        ),
      ],
    ),
    );
  }

  // ── Top Selling Items ───────────────────────────────────────────────────────
  Widget _buildTopSellingSection(bool isUrdu, List<TopSellingItem> topItems) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.white;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.04),
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
          Row(
            mainAxisAlignment:
                isUrdu ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUrdu)
                Icon(
                  Icons.star_border_rounded,
                  color: primaryTextColor,
                  size: 22,
                ),
              if (!isUrdu) const SizedBox(width: 6),
              Text(
                _showingExpenseItems
                    ? (isUrdu ? 'Top Expenses (No sales yet)' : 'Top Expenses (No sales yet)')
                    : (isUrdu ? 'ٹاپ سیلنگ آئٹمز' : 'Top Selling Items'),
                style: isUrdu
                    ? TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor)
                    : GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor),
              ),
              if (isUrdu) const SizedBox(width: 6),
              if (isUrdu)
                Icon(
                  Icons.star_border_rounded,
                  color: primaryTextColor,
                  size: 22,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (topItems.isEmpty)
            Text(
              isUrdu
                  ? 'Abhi is hafte koi sale ya expense insight me nahi.'
                  : 'No weekly sales/expense items in insight yet.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowColor = isDark
        ? AppColors.primary.withValues(alpha: 0.42)
        : const Color(0xFFEFF5E5);
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (!isUrdu)
            Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(color: item.iconBg, shape: BoxShape.circle),
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
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor),
                  ),
                  Text(
                    item.qtyEnglish,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor),
                  ),
                ],
              ),
            ),
          if (isUrdu)
            Text(
              item.qtyUrdu,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor),
            ),
          if (isUrdu) const Spacer(),
          if (isUrdu)
            Text(
              item.nameUrdu,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor),
            ),
          if (isUrdu) const SizedBox(width: 10),
          if (isUrdu)
            Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(color: item.iconBg, shape: BoxShape.circle),
              child: Icon(item.icon, size: 18, color: item.iconColor),
            ),
        ],
      ),
    );
  }

  // ── AI Suggestions ──────────────────────────────────────────────────────────
  Widget _buildLearningBadge(bool isUrdu) {
    final kpis = Map<String, dynamic>.from(_latestInsight?['kpis'] as Map? ?? const {});
    final parseAccuracy = ((kpis['voice_parse_accuracy_pct'] as num?) ?? 0).toDouble();

    return InkWell(
      onTap: () => context.push(AppRoutes.learningStats),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF8F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: Color(0xFF5D4037),
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isUrdu
                    ? 'Learning Accuracy ${parseAccuracy.toStringAsFixed(1)}%'
                    : 'Learning Accuracy ${parseAccuracy.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3E2723),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF5D4037)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptationKpis(bool isUrdu) {
    final kpis = Map<String, dynamic>.from(_latestInsight?['kpis'] as Map? ?? const {});
    final parseAccuracy = ((kpis['voice_parse_accuracy_pct'] as num?) ?? 0).toDouble();
    final recommendationAcceptance =
        ((kpis['recommendation_acceptance_pct'] as num?) ?? 0).toDouble();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDark ? AppColors.darkCard : AppColors.white;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? 'Parsing Accuracy' : 'Parsing Accuracy',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${parseAccuracy.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.actionGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? 'Recommendation Acceptance' : 'Recommendation Acceptance',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${recommendationAcceptance.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiSuggestions(bool isUrdu, List<AiSuggestion> suggestions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryLight : AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(
                color: AppColors.white.withValues(alpha: 0.4), width: 1.2)
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      child: Column(
        crossAxisAlignment:
            isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment:
                  isUrdu ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isUrdu)
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded,
                        color: AppColors.white, size: 18),
                  ),
                if (!isUrdu) const SizedBox(width: 8),
                Text(
                  isUrdu ? 'تجاویز AI' : 'AI Suggestions',
                  style: isUrdu
                      ? const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white)
                      : GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white),
                ),
                if (isUrdu) const SizedBox(width: 8),
                if (isUrdu)
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded,
                        color: AppColors.white, size: 18),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowColor = isDark
        ? AppColors.primary.withValues(alpha: 0.42)
        : const Color(0xFFE8EFF2);
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (!isUrdu)
            Icon(suggestion.icon, size: 22, color: suggestion.iconColor),
          if (!isUrdu) const SizedBox(width: 10),
          Expanded(
            child: Text(
              LocalizedRecommendation(
                textEnglish: suggestion.textEnglish,
                textUrdu: suggestion.textUrdu,
              ).displayText(isUrdu),
              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isUrdu ? TextAlign.right : TextAlign.left,
              style: isUrdu
                  ? TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor)
                  : GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor),
            ),
          ),
          const SizedBox(width: 4),
          FeedbackThumbButton(
            isUp: true,
            isSelected: _recommendationVotes[_feedbackKey(suggestion)] == true,
            onTap: () => _submitRecommendationFeedback(
              _feedbackKey(suggestion),
              true,
            ),
          ),
          FeedbackThumbButton(
            isUp: false,
            isSelected: _recommendationVotes[_feedbackKey(suggestion)] == false,
            onTap: () => _submitRecommendationFeedback(
              _feedbackKey(suggestion),
              false,
            ),
          ),
          if (isUrdu) const SizedBox(width: 10),
          if (isUrdu)
            Icon(suggestion.icon, size: 22, color: suggestion.iconColor),
        ],
      ),
    );
  }
}
