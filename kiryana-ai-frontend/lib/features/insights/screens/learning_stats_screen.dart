import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/latest_insight_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/animated_bulb_indicator.dart';
import '../../../core/widgets/app_widgets.dart';

class LearningStatsScreen extends ConsumerStatefulWidget {
  const LearningStatsScreen({super.key});

  @override
  ConsumerState<LearningStatsScreen> createState() => _LearningStatsScreenState();
}

class _LearningStatsScreenState extends ConsumerState<LearningStatsScreen> {
  bool _loading = true;
  Map<String, dynamic> _kpis = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    final cached = ref.read(latestInsightProvider).data?['kpis'];
    if (cached is Map) {
      setState(() {
        _kpis = Map<String, dynamic>.from(cached);
        _loading = false;
      });
      _load(silent: true);
      return;
    }
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final userId = await ApiService().currentUserId();
      final kpis = await ApiService().getAdaptationKpis(userId);
      if (!mounted) return;
      setState(() => _kpis = kpis);
      ref.read(latestInsightProvider.notifier).mergePatch({'kpis': kpis});
    } catch (error) {
      if (mounted && _kpis.isEmpty) {
        AppToast.show(context, ApiService().errorMessage(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmRefine(bool isUrdu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isUrdu ? 'AI سے سیکھنے کو بہتر بنائیں؟' : 'Refine learning with AI?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
          content: Text(
            isUrdu
                ? 'آپ کے voice feedback اور thumbs up/down سے AI دوبارہ patterns سمجھے گا اور اگلی تجاویز بہتر بنائے گا۔'
                : 'AI will re-read your voice feedback and thumbs, update shop patterns, and improve future suggestions.',
            style: GoogleFonts.inter(height: 1.45, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: Text(isUrdu ? 'بہتر بنائیں' : 'Refine'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    await _refine(isUrdu);
  }

  Future<void> _refine(bool isUrdu) async {
    try {
      final userId = await ApiService().currentUserId();
      await ApiService().refineLearning(userId);
      await _load(silent: _kpis.isNotEmpty);
      if (mounted) {
        AppToast.show(
          context,
          isUrdu ? 'سیکھنے کو بہتر بنا دیا گیا' : 'Learning refined',
        );
      }
    } catch (error) {
      if (mounted) AppToast.show(context, ApiService().errorMessage(error), isError: true);
    }
  }

  Future<void> _clear() async {
    final isUrdu = ref.read(languageProvider).languageCode == 'ur';
    try {
      final userId = await ApiService().currentUserId();
      await ApiService().clearLearning(userId);
      await _load(silent: _kpis.isNotEmpty);
      if (mounted) {
        AppToast.show(
          context,
          isUrdu ? 'سیکھنا صاف کر دیا گیا' : 'Learning cleared',
        );
      }
    } catch (error) {
      if (mounted) AppToast.show(context, ApiService().errorMessage(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUrdu = ref.watch(languageProvider).languageCode == 'ur';
    final bg = isDark ? AppColors.primary : AppColors.secondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;
    final textPrimary = isDark ? AppColors.white : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.textSecondary;
    final showSpinner = _loading && _kpis.isEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: Text(isUrdu ? 'Learning Statistics' : 'Learning Statistics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: showSpinner
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
                children: [
                  _learningExplainerTile(isUrdu),
                  const SizedBox(height: 14),
                  _metric(
                    'Parsing Accuracy',
                    '${((_kpis['voice_parse_accuracy_pct'] ?? 0) as num).toStringAsFixed(1)}%',
                    cardBg,
                    textPrimary,
                  ),
                  const SizedBox(height: 10),
                  _metric(
                    'Recommendation Acceptance',
                    '${((_kpis['recommendation_acceptance_pct'] ?? 0) as num).toStringAsFixed(1)}%',
                    cardBg,
                    textPrimary,
                  ),
                  const SizedBox(height: 10),
                  _metric(
                    'Voice Feedback Samples',
                    '${_kpis['voice_feedback_total'] ?? 0}',
                    cardBg,
                    textPrimary,
                  ),
                  const SizedBox(height: 10),
                  _metric(
                    'Recommendation Feedback Samples',
                    '${_kpis['recommendation_feedback_total'] ?? 0}',
                    cardBg,
                    textPrimary,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _confirmRefine(isUrdu),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 22),
                    label: Text(
                      isUrdu
                          ? 'AI سے سیکھنے کو بہتر بنائیں'
                          : 'Refine Learning with AI',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    label: Text(
                      isUrdu ? 'موجودہ سیکھنا صاف کریں' : 'Clear Current Learning',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      foregroundColor: AppColors.errorReadable,
                      backgroundColor: AppColors.errorReadable.withValues(alpha: 0.08),
                      side: const BorderSide(color: AppColors.errorReadable, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _learningExplainerTile(bool isUrdu) {
    final text = isUrdu
        ? 'Jab aap voice logs par sahi/galat batate hain aur AI suggestions par thumbs dete hain, '
            'to app aapki dukaan ke patterns seekhti hai aur agli recommendations behtar banati hai.'
        : 'When you mark voice logs correct/wrong and give thumbs on AI suggestions, '
            'the app learns your shop patterns and improves future recommendations.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFECB3), Color(0xFFFFD54F), Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnimatedBulbIndicator(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? 'Learning kaise hoti hai' : 'How learning works',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3E2723),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4E342E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color cardBg, Color textPrimary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
