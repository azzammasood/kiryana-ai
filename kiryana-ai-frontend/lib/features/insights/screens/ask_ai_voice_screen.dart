import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/gemini_sparkle_indicator.dart';
import '../../voice/services/audio_picker_stub.dart'
    if (dart.library.html) '../../voice/services/audio_picker_web.dart';

class AskAiVoiceScreen extends ConsumerStatefulWidget {
  const AskAiVoiceScreen({super.key});

  @override
  ConsumerState<AskAiVoiceScreen> createState() => _AskAiVoiceScreenState();
}

class _AskAiVoiceScreenState extends ConsumerState<AskAiVoiceScreen> {
  bool _recording = false;
  bool _loading = false;
  String _transcript = '';
  String _answer = '';
  String? _hintQuestion;

  static const List<String> _suggestedQuestions = [
    'Is hafte munafa kaise barhayein?',
    'Pehle kin items ka stock refill karein?',
    'Kharcha sales se zyada kyun hai?',
    'Kal subah shop par kya focus karein?',
  ];

  @override
  void dispose() {
    cancelMicRecording();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      setState(() => _loading = true);
      try {
        final audio = await stopMicRecording();
        if (audio == null) return;
        final api = ApiService();
        final userId = await api.currentUserId();
        final hint = _hintQuestion?.trim();
        final result = await api.askVoiceInsightQuestion(
          bytes: audio.bytes,
          fileName: audio.fileName,
          userId: userId,
          questionHint: hint,
        );
        final text = (result['transcription'] ?? '').toString().trim();
        final answer = (result['answer'] ?? '').toString();
        final displayQuestion = _displayQuestion(text, hint);
        if (!mounted) return;
        setState(() {
          _recording = false;
          _transcript = displayQuestion;
          _answer = answer;
        });
      } catch (error) {
        if (mounted) {
          AppToast.show(context, ApiService().errorMessage(error), isError: true);
          setState(() => _recording = false);
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    try {
      await startMicRecording();
      setState(() {
        _recording = true;
        _answer = '';
        _transcript = '';
      });
    } catch (error) {
      if (!mounted) return;
      AppToast.show(context, ApiService().errorMessage(error), isError: true);
    }
  }

  String _displayQuestion(String transcription, String? hint) {
    final hintText = hint?.trim() ?? '';
    final tx = transcription.trim();
    final lower = tx.toLowerCase();
    final weak = tx.isEmpty ||
        tx.length < 12 ||
        lower.contains('kuch aisa') ||
        lower.contains('something like');
    if (hintText.isNotEmpty && weak) return hintText;
    return tx.isEmpty ? hintText : tx;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.primary : AppColors.secondary;
    const cardBg = AppColors.white;
    const cardTitleColor = AppColors.textPrimary;
    const cardBodyColor = Color(0xFF374151);
    final subtitleColor =
        isDark ? AppColors.white.withValues(alpha: 0.78) : AppColors.textSecondary;
    final showAnswers = _transcript.isNotEmpty || _answer.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Get help from AI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: GeminiSparkleIndicator(size: 120)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'AI can help answer your questions — profit, stock, expenses, or shop planning.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.45,
                        color: subtitleColor,
                      ),
                    ),
                    if (_hintQuestion != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _hintQuestion!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 60),
                    if (_loading)
                      Column(
                        children: [
                          const GeminiSparkleIndicator(size: 150),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Gemini is preparing your answer...',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      )
                    else if (!showAnswers)
                      const Center(child: GeminiSparkleIndicator(size: 150)),
                    if (showAnswers) ...[
                      const SizedBox(height: 24),
                      if (_transcript.isNotEmpty)
                        _card('Aap ne poocha', _transcript, cardBg, cardTitleColor, cardBodyColor),
                      if (_answer.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _card('AI ka jawab', _answer, cardBg, cardTitleColor, cardBodyColor),
                      ],
                    ],
                    if (!showAnswers && !_loading) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Suggested sawalat',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestedQuestions.map((q) {
                          final selected = _hintQuestion == q;
                          return ActionChip(
                            label: Text(q),
                            onPressed: () => setState(() => _hintQuestion = q),
                            backgroundColor: selected
                                ? AppColors.actionGreen.withValues(alpha: 0.2)
                                : (isDark
                                    ? AppColors.darkCard
                                    : const Color(0xFFE8EFF2)),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                              color: isDark ? AppColors.white : AppColors.textPrimary,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _toggleRecording,
                icon: Icon(_recording ? Icons.stop_circle : Icons.mic_rounded),
                label: Text(
                  _loading
                      ? 'Processing...'
                      : (_recording ? 'Done' : 'Speak'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    String title,
    String body,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.inter(color: textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}
