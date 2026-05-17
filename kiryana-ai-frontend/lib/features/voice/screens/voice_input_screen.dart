import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/mock/mock_voice_data.dart';
import '../widgets/audio_waveform.dart';
import '../widgets/parsed_details_card.dart';
import '../widgets/voice_action_buttons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';
import '../../../../core/widgets/app_widgets.dart';

class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen> {
  bool _isListening = true;
  bool _isProcessing = false;
  bool _isParsed = false;
  bool _isSaving = false;

  void _onDoneListening() {
    setState(() {
      _isListening = false;
      _isProcessing = true;
    });

    // Simulate backend processing audio and returning parsed JSON
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isParsed = true;
        });
      }
    });
  }

  void _onRetry() {
    setState(() {
      _isParsed = false;
      _isProcessing = false;
      _isListening = true;
    });
  }

  Future<void> _onCorrect() async {
    final isUrdu = ref.read(languageProvider).languageCode == 'ur';
    setState(() {
      _isSaving = true;
    });
    
    // Simulate backend saving
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      AppToast.show(
        context,
        isUrdu ? 'وائس کمانڈ محفوظ ہو گئی!' : 'Voice command saved to backend!',
      );
      context.go('/dashboard');
    }
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
              Image.asset('assets/images/topbar-logo.png', width: 28, height: 28),
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
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.white),
              ),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
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
                            _isProcessing ? 'پروسیسنگ ہو رہی ہے...' : (_isParsed ? AppStrings.speakAgainUrdu : AppStrings.listeningUrdu),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.white : AppColors.primary,
                              height: 1.4,
                            ),
                          ),
                        
                        if (isUrdu) const SizedBox(height: AppSpacing.sm),
                        Text(
                          _isProcessing 
                            ? (isUrdu ? 'Processing Audio...' : 'Processing Audio...') 
                            : (_isParsed ? AppStrings.speakAgainEnglish : AppStrings.listeningEnglish),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: isUrdu ? 16 : 28,
                            fontWeight: isUrdu ? FontWeight.w500 : FontWeight.w700,
                            color: isUrdu 
                              ? (isDark ? AppColors.white.withValues(alpha: 0.7) : AppColors.textSecondary)
                              : (isDark ? AppColors.white : AppColors.primary),
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        // Waveform Animation (Always show, stops when not listening)
                        AudioWaveform(isListening: _isListening),
                        
                        if (_isParsed) ...[
                          const SizedBox(height: 40),
                          // Transcription Text in a white box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              VoiceMockData.rawTranscription,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Parsed Details showing up below after transcription
                          const ParsedDetailsCard(),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Bottom Actions
                if (_isListening)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ElevatedButton.icon(
                      onPressed: _onDoneListening,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        isUrdu ? 'مکمل کریں (Done)' : 'Done',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.actionGreen : AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  )
                else if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                else if (_isParsed)
                  VoiceActionButtons(
                    onCorrect: _onCorrect,
                    onRetry: _onRetry,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
