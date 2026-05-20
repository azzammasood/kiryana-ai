import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../logs/providers/transaction_provider.dart';
import '../widgets/audio_waveform.dart';
import '../widgets/parsed_details_card.dart';
import '../widgets/voice_action_buttons.dart';
import '../services/audio_picker_stub.dart'
    if (dart.library.html) '../services/audio_picker_web.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/insight_refresh_provider.dart';
import '../../../core/providers/latest_insight_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../../core/widgets/animated_topbar_logo.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/saving_overlay.dart';

class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen>
    with SingleTickerProviderStateMixin {
  bool _isListening = true;
  bool _isProcessing = false;
  bool _isParsed = false;
  bool _isSaving = false;
  bool _isRecorderReady = false;
  String _transcription = '';
  String? _audioUrl;
  Map<String, dynamic>? _parsedTransaction;
  List<Map<String, dynamic>> _parsedTransactions = [];
  String _engineLabel = 'gemini-2.5-flash';
  late final AnimationController _geminiController;

  @override
  void initState() {
    super.initState();
    _geminiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRecording());
  }

  @override
  void dispose() {
    _geminiController.dispose();
    cancelMicRecording();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await startMicRecording();
      if (!mounted) return;
      setState(() {
        _isRecorderReady = true;
        _isListening = true;
      });
    } catch (error) {
      if (!mounted) return;
      AppToast.show(context, ApiService().errorMessage(error), isError: true);
      setState(() {
        _isRecorderReady = false;
        _isListening = true;
      });
    }
  }

  Future<void> _onDoneListening() async {
    if (!_isRecorderReady) {
      await _startRecording();
      return;
    }
    setState(() {
      _isListening = false;
      _isProcessing = true;
    });

    try {
      final picked = await stopMicRecording();
      if (picked == null) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _isListening = true;
          _isRecorderReady = false;
        });
        await _startRecording();
        return;
      }
      final userId = await ApiService().currentUserId();
      final result = await ApiService().processVoiceBytes(
        bytes: picked.bytes,
        fileName: picked.fileName,
        userId: userId,
      );
      final transactions = (result['transactions'] as List<dynamic>? ?? []);
      if (transactions.isEmpty) {
        throw Exception(result['user_friendly_message'] ??
            'Audio se transaction nahi nikli');
      }
      if (!mounted) return;
      setState(() {
        _transcription =
            (result['raw_transcript'] ?? result['normalized_transcript'] ?? '')
                .toString();
        _audioUrl = result['audio_url']?.toString();
        _parsedTransactions = transactions
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _parsedTransaction = _parsedTransactions.first;
        _engineLabel = (result['engine'] ?? 'gemini-2.5-flash').toString();
        _isProcessing = false;
        _isParsed = true;
      });
    } catch (error) {
      if (!mounted) return;
      AppToast.show(context, ApiService().errorMessage(error), isError: true);
      setState(() {
        _isProcessing = false;
        _isListening = true;
        _isRecorderReady = false;
        _isParsed = false;
      });
      await _startRecording();
    }
  }

  Future<void> _onRecordAction() async {
    if (_isProcessing) return;
    if (_isRecorderReady) {
      await _onDoneListening();
      return;
    }
    await _startRecording();
  }

  void _onRetry() {
    _submitVoiceFeedback(false);
    setState(() {
      _isParsed = false;
      _isProcessing = false;
      _isListening = true;
      _transcription = '';
      _audioUrl = null;
      _parsedTransaction = null;
      _parsedTransactions = [];
    });
    _startRecording();
  }

  Future<void> _onCorrect() async {
    if (_isSaving) return;
    final isUrdu = ref.read(languageProvider).languageCode == 'ur';
    setState(() {
      _isSaving = true;
    });

    try {
      if (_parsedTransactions.isEmpty && _parsedTransaction != null) {
        _parsedTransactions = [_parsedTransaction!];
      }
      final userId = await ApiService().currentUserId();
      final saveFutures = _parsedTransactions.map((parsed) {
        final txDate = DateTime.tryParse(
              (parsed['transaction_date'] ?? '').toString(),
            ) ??
            DateTime.now();
        final transaction = TransactionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titleUrdu: parsed['item_name'].toString(),
          titleEnglish: parsed['item_name'].toString(),
          tag: '${parsed['quantity'] ?? '-'} ${parsed['unit'] ?? ''}'.trim(),
          date: txDate,
          amount: ((parsed['amount'] as num?) ?? 0).round(),
          isSale: parsed['transaction_type'] == 'sale',
          iconType: parsed['transaction_type'] == 'sale' ? 'sale' : 'bill',
        );
        final payload = transaction.toApiJson(userId)
          ..['raw_text'] = _transcription
          ..['audio_url'] = _audioUrl;
        return ApiService().saveTransaction(payload);
      }).toList();

      final savedRows = await Future.wait(saveFutures);
      final firstId = (savedRows.first['id'] as num?)?.toInt();

      ref.invalidate(transactionsProvider);
      bumpInsightRefresh(ref);

      unawaited(
        _submitVoiceFeedback(
          true,
          sourceTransactionId: firstId,
          correctedPayload: _parsedTransactions.first,
        ),
      );
      unawaited(_refreshInsightInBackground(userId));
    } catch (error) {
      if (mounted) {
        AppToast.show(context, ApiService().errorMessage(error), isError: true);
        setState(() {
          _isSaving = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.actionGreen,
          size: 48,
        ),
        title: Text(
          isUrdu ? 'Log save ho gaya' : 'Log saved',
          style: const TextStyle(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        content: Text(
          isUrdu
              ? 'Aap ki voice entry save ho chuki hai.'
              : 'Your voice log was saved successfully.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isUrdu ? 'Theek hai' : 'OK'),
          ),
        ],
      ),
    );
    if (mounted) context.go('/dashboard');
  }

  Future<void> _refreshInsightInBackground(int userId) async {
    try {
      final refreshed = await ApiService().refreshInsightsLight(userId);
      if (!mounted || refreshed == null) return;
      ref.read(latestInsightProvider.notifier).applyInsight(refreshed);
    } catch (_) {
      // Non-blocking background refresh.
    }
  }

  Future<void> _submitVoiceFeedback(
    bool isCorrect, {
    int? sourceTransactionId,
    Map<String, dynamic>? correctedPayload,
  }) async {
    try {
      final userId = await ApiService().currentUserId();
      await ApiService().submitVoiceFeedback(
        userId: userId,
        isCorrect: isCorrect,
        sourceTransactionId: sourceTransactionId,
        rawTranscript: _transcription,
        parsedPayload: _parsedTransaction,
        correctedPayload: correctedPayload,
      );
    } catch (_) {
      // Feedback capture should not block primary UX flow.
    }
  }

  Widget _buildProcessingGeminiIndicator() {
    return AnimatedBuilder(
      animation: _geminiController,
      builder: (context, _) {
        final t = _geminiController.value;
        final pulse = 0.96 + (0.08 * (0.5 - (t - 0.5).abs()) * 2);
        return Transform.scale(
          scale: pulse,
          child: SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 136,
                  height: 136,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7DD3FC).withValues(alpha: 0.20),
                        blurRadius: 34,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
                Transform.rotate(
                  angle: t * 6.28318530718,
                  child: Container(
                    width: 118,
                    height: 118,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0x004F46E5),
                          Color(0xFF4F46E5),
                          Color(0xFF7DD3FC),
                          Color(0x004F46E5),
                        ],
                        stops: [0.00, 0.45, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3645).withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7DD3FC).withValues(alpha: 0.22),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -(t * 6.28318530718),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 44,
                    color: Color(0xFFB6ECFF),
                  ),
                ),
                ...List.generate(4, (index) {
                  final angle = (index * 1.57079632679) + (t * 6.28318530718);
                  final x = 47 * (index.isEven ? 1 : -1);
                  final y = 47 * (index < 2 ? 1 : -1);
                  return Transform.rotate(
                    angle: angle,
                    child: Transform.translate(
                      offset: Offset(x.toDouble(), y.toDouble()),
                      child: Container(
                        width: index.isEven ? 9 : 7,
                        height: index.isEven ? 9 : 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7DD3FC),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= AppSpacing.mobileBreakpoint;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';
    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              const AnimatedTopBarLogo(size: 28),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  isUrdu ? 'Speak' : 'Speak',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              if (isUrdu) ...[
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'بولیں',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.white.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.white),
              ),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? AppSpacing.maxContentWidth : double.infinity,
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xl),

                        // Main Status Text
                        if (isUrdu)
                          Text(
                            _isProcessing
                                ? 'پروسیسنگ ہو رہی ہے...'
                                : (_isParsed
                                    ? AppStrings.speakAgainUrdu
                                    : AppStrings.listeningUrdu),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? AppColors.white : AppColors.primary,
                              height: 1.4,
                            ),
                          ),

                        if (isUrdu) const SizedBox(height: AppSpacing.sm),
                        Text(
                          _isProcessing
                              ? (isUrdu
                                  ? 'Processing Audio...'
                                  : 'Processing Audio...')
                              : (_isParsed
                                  ? AppStrings.speakAgainEnglish
                                  : AppStrings.listeningEnglish),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: isUrdu ? 16 : 28,
                            fontWeight:
                                isUrdu ? FontWeight.w500 : FontWeight.w700,
                            color: isUrdu
                                ? (isDark
                                    ? AppColors.white.withValues(alpha: 0.7)
                                    : AppColors.textSecondary)
                                : (isDark
                                    ? AppColors.white
                                    : AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Powered by Gemini | Model: $_engineLabel',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.white.withValues(alpha: 0.75)
                                : AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 60),

                        // During processing, show AI indicator instead of static waveform.
                        if (_isProcessing)
                          Column(
                            children: [
                              _buildProcessingGeminiIndicator(),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                isUrdu
                                    ? 'Gemini آپ کی آواز سمجھ رہا ہے'
                                    : 'Gemini is understanding your voice',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.white.withValues(alpha: 0.8)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          )
                        else
                          AudioWaveform(isListening: _isListening),

                        if (_isParsed) ...[
                          const SizedBox(height: 40),
                          // Transcription Text in a white box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                                horizontal: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _transcription,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (_parsedTransactions.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Text(
                                'Detected ${_parsedTransactions.length} entries. All will be saved.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ..._parsedTransactions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final tx = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_parsedTransactions.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'Entry ${index + 1} of ${_parsedTransactions.length}',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.white.withValues(alpha: 0.85)
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ParsedDetailsCard(data: tx),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom Actions — visible while listening OR processing (retry mic after errors)
                if (!_isParsed)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _onRecordAction,
                      icon: Icon(
                        _isProcessing
                            ? Icons.hourglass_top_rounded
                            : (_isRecorderReady
                                ? Icons.check_circle_outline_rounded
                                : Icons.mic_rounded),
                      ),
                      label: Text(
                        _isProcessing
                            ? (isUrdu ? 'Processing...' : 'Processing...')
                            : (_isRecorderReady
                                ? 'Done'
                                : (isUrdu
                                    ? 'Microphone allow karein'
                                    : 'Allow microphone...')),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? AppColors.actionGreen : AppColors.primary,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: (isDark
                                ? AppColors.actionGreen
                                : AppColors.primary)
                            .withValues(alpha: 0.45),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  )
                else if (_isParsed)
                  VoiceActionButtons(
                    onCorrect: _isSaving ? () {} : _onCorrect,
                    onRetry: _isSaving ? () {} : _onRetry,
                    isBusy: _isSaving,
                  ),
              ],
            ),
          ),
        ),
      ),
          if (_isSaving)
            SavingOverlay(
              title: isUrdu ? 'Log save ho raha hai' : 'Saving your log',
              subtitle: isUrdu
                  ? 'Thori dair ruken, entry database mein likhi ja rahi hai'
                  : 'Please wait while we save your entry',
            ),
        ],
      ),
    );
  }
}
