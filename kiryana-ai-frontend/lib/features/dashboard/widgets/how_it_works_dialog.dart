import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/widgets/gemini_agent_icon.dart';

class _AgentInfo {
  final String nameEn;
  final String nameUr;
  final String roleEn;
  final String roleUr;
  final String descEn;
  final String descUr;
  final IconData? icon;
  final String? imageAsset;
  final List<Color> gradient;

  const _AgentInfo({
    required this.nameEn,
    required this.nameUr,
    required this.roleEn,
    required this.roleUr,
    required this.descEn,
    required this.descUr,
    this.icon,
    this.imageAsset,
    required this.gradient,
  });
}

const _agents = [
  _AgentInfo(
    nameEn: 'Voice Agent',
    nameUr: 'وائس ایجنٹ',
    roleEn: 'ai_voice module',
    roleUr: 'آواز سمجھنے والا',
    descEn: 'Listens to Urdu / Roman Urdu and turns speech into sales & expenses.',
    descUr: 'اردو یا رومن اردو سن کر bikri aur kharcha log karta hai.',
    icon: Icons.mic_rounded,
    gradient: [Color(0xFF5B4FCF), Color(0xFF7B6FE8)],
  ),
  _AgentInfo(
    nameEn: 'Ledger Agent',
    nameUr: 'لیجر ایجنٹ',
    roleEn: 'Database',
    roleUr: 'ڈیٹا محفوظ',
    descEn: 'Saves every confirmed voice log to your shop ledger in Supabase.',
    descUr: 'Har sahi voice entry ko dukaan ke ledger mein save karta hai.',
    icon: Icons.storage_rounded,
    gradient: [Color(0xFF0B6E78), Color(0xFF159AAB)],
  ),
  _AgentInfo(
    nameEn: 'Pattern Agent',
    nameUr: 'پیٹرن ایجنٹ',
    roleEn: 'ai_insights module',
    roleUr: 'رجحانات',
    descEn: 'Finds top items, slow days, and margin patterns from your week.',
    descUr: 'Hafte ke top items aur business patterns nikalta hai.',
    icon: Icons.insights_rounded,
    gradient: [Color(0xFF1B6D24), Color(0xFF43A047)],
  ),
  _AgentInfo(
    nameEn: 'Anomaly Agent',
    nameUr: 'انومالی ایجنٹ',
    roleEn: 'Gemini 2.5 Flash',
    roleUr: 'غیر معمولی رجحان',
    descEn: 'Spots unusual sales or expense spikes and explains them simply.',
    descUr: 'Ajeeb sales/expense changes detect karke batata hai.',
    icon: Icons.radar_rounded,
    gradient: [Color(0xFFE65100), Color(0xFFFFB74D)],
  ),
  _AgentInfo(
    nameEn: 'Insight Agent',
    nameUr: 'ان سائٹ ایجنٹ',
    roleEn: 'Gemini 2.5 Flash',
    roleUr: 'ہفتہ وار مشورہ',
    descEn: 'Writes weekly Roman Urdu / English tips and profit summary.',
    descUr: 'Hafta war report aur 3 practical tips banata hai.',
    icon: Icons.auto_awesome_rounded,
    gradient: [AppColors.aiPurple, AppColors.aiBlue, AppColors.aiPink],
  ),
  _AgentInfo(
    nameEn: 'Planning Agent',
    nameUr: 'پلاننگ ایجنٹ',
    roleEn: 'Antigravity step 5',
    roleUr: 'عملی اقدامات',
    descEn: 'Turns insights into actions and learns from your thumbs up/down.',
    descUr: 'Tips ko actions mein badalta hai aur feedback se seekhta hai.',
    icon: Icons.lightbulb_outline_rounded,
    gradient: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
  ),
  _AgentInfo(
    nameEn: 'Notify Agent',
    nameUr: 'نوٹیفائی ایجنٹ',
    roleEn: 'Twilio WhatsApp',
    roleUr: 'واٹس ایپ رپورٹ',
    descEn: 'Can send your weekly report to WhatsApp when enabled.',
    descUr: 'Chaho to hafta war report WhatsApp par bhej sakta hai.',
    imageAsset: 'assets/images/whatsapp-icon.png',
    gradient: [Color(0xFF25D366), Color(0xFF128C7E)],
  ),
];

void showHowItWorksDialog(BuildContext context, WidgetRef ref) {
  final isUrdu = ref.read(languageProvider).languageCode == 'ur';

  showDialog<void>(
    context: context,
    barrierColor: AppColors.primary.withValues(alpha: 0.55),
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final surface = isDark ? AppColors.primaryLight : AppColors.white;
      final textPrimary =
          isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
      final textSecondary =
          isDark ? AppColors.white.withValues(alpha: 0.75) : AppColors.textSecondary;

      return Dialog(
        backgroundColor: surface,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.82,
            maxWidth: 420,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
                child: Row(
                  children: [
                    const GeminiAgentIcon(size: 44, iconSize: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrdu ? 'Kiryana AI کیسے کام کرتا ہے؟' : 'How Kiryana AI Works',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUrdu
                                ? 'متعدد AI ایجنٹس مل کر voice se action تک'
                                : 'Multiple AI agents — voice to action',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close_rounded, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    children: [
                      for (var i = 0; i < _agents.length; i++) ...[
                        _AgentCard(
                          agent: _agents[i],
                          isUrdu: isUrdu,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          isDark: isDark,
                        ),
                        if (i < _agents.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              size: 18,
                              color: AppColors.primary.withValues(alpha: 0.45),
                            ),
                          ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timeline_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isUrdu
                                    ? 'ہر قدم AI System Logs میں دیکھیں — جیسے AI Sessions'
                                    : 'See every step in AI System Logs — same as AI Sessions',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.push('/ai-logs');
                        },
                        icon: const Icon(Icons.history_rounded, size: 18),
                        label: Text(
                          isUrdu ? 'AI Sessions دیکھیں' : 'View AI Sessions',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isUrdu ? 'سمجھ آ گیا' : 'Got it',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AgentCard extends StatelessWidget {
  final _AgentInfo agent;
  final bool isUrdu;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _AgentCard({
    required this.agent,
    required this.isUrdu,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rowBg = isDark
        ? AppColors.primary.withValues(alpha: 0.35)
        : const Color(0xFFF4F8F9);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: agent.gradient.length >= 2
                    ? agent.gradient
                    : [agent.gradient.first, agent.gradient.first],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: agent.gradient.first.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: agent.imageAsset != null
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      agent.imageAsset!,
                      fit: BoxFit.contain,
                    ),
                  )
                : Icon(agent.icon, color: AppColors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? agent.nameUr : agent.nameEn,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUrdu ? agent.roleUr : agent.roleEn,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF7DD3FC)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isUrdu ? agent.descUr : agent.descEn,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.88)
                        : textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
