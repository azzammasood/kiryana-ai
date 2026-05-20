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

  Future<void> _refine() async {
    try {
      final userId = await ApiService().currentUserId();
      await ApiService().refineLearning(userId);
      await _load(silent: _kpis.isNotEmpty);
      if (mounted) AppToast.show(context, 'Learning refined');
    } catch (error) {
      if (mounted) AppToast.show(context, ApiService().errorMessage(error), isError: true);
    }
  }

  Future<void> _clear() async {
    try {
      final userId = await ApiService().currentUserId();
      await ApiService().clearLearning(userId);
      await _load(silent: _kpis.isNotEmpty);
      if (mounted) AppToast.show(context, 'Learning cleared');
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
                    onPressed: _refine,
                    icon: const Icon(Icons.lightbulb_rounded),
                    label: const Text('Refine Learning with AI'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(
                      'Clear Current Learning',
                      style: TextStyle(color: textSecondary),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      foregroundColor: AppColors.errorReadable,
                      side: BorderSide(
                        color: AppColors.errorReadable.withValues(alpha: 0.5),
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
