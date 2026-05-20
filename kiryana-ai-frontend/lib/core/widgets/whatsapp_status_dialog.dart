import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

enum WhatsAppDialogPhase { sending, success, failed }

Future<void> showWhatsAppStatusDialog({
  required BuildContext context,
  required bool isUrdu,
  required Future<Map<String, dynamic>> Function() send,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.primary.withValues(alpha: 0.6),
    builder: (ctx) => _WhatsAppStatusDialog(
      isUrdu: isUrdu,
      send: send,
    ),
  );
}

class _WhatsAppStatusDialog extends StatefulWidget {
  final bool isUrdu;
  final Future<Map<String, dynamic>> Function() send;

  const _WhatsAppStatusDialog({
    required this.isUrdu,
    required this.send,
  });

  @override
  State<_WhatsAppStatusDialog> createState() => _WhatsAppStatusDialogState();
}

class _WhatsAppStatusDialogState extends State<_WhatsAppStatusDialog> {
  WhatsAppDialogPhase _phase = WhatsAppDialogPhase.sending;
  String _detail = '';

  @override
  void initState() {
    super.initState();
    _runSend();
  }

  Future<void> _runSend() async {
    try {
      final result = await widget.send();
      if (!mounted) return;
      final sent = result['sent'] == true;
      setState(() {
        _phase = sent ? WhatsAppDialogPhase.success : WhatsAppDialogPhase.failed;
        _detail = (result['detail'] ?? '').toString();
        if (sent) {
          final to = (result['to'] ?? '').toString();
          final extra = (result['detail'] ?? '').toString();
          if (extra.isNotEmpty) {
            _detail = extra;
          } else if (to.isNotEmpty) {
            _detail = to;
          }
        }
      });
      if (sent) {
        await Future<void>.delayed(const Duration(milliseconds: 1800));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = WhatsAppDialogPhase.failed;
        _detail = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = widget.isUrdu;

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/whatsapp-icon.png',
              width: 72,
              height: 72,
            ),
            const SizedBox(height: 20),
            if (_phase == WhatsAppDialogPhase.sending) ...[
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF25D366),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isUrdu ? 'واٹس ایپ پر بھیج رہے ہیں' : 'Sending to WhatsApp',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isUrdu
                    ? 'Thori dair ruken…'
                    : 'Please wait a moment…',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ] else if (_phase == WhatsAppDialogPhase.success) ...[
              Icon(
                Icons.check_circle_rounded,
                size: 52,
                color: AppColors.actionGreen,
              ),
              const SizedBox(height: 16),
              Text(
                isUrdu ? 'واٹس ایپ پر بھیج دیا' : 'Sent on WhatsApp',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_detail.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _detail,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ] else ...[
              Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: AppColors.errorReadable,
              ),
              const SizedBox(height: 16),
              Text(
                isUrdu ? 'واٹس ایپ نہیں بھیجی گئی' : 'Could not send on WhatsApp',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _detail.isNotEmpty
                    ? _detail
                    : (isUrdu
                        ? 'Twilio sandbox: pehle apne number se join message bhejein.'
                        : 'Twilio sandbox: join the sandbox from your WhatsApp first.'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(isUrdu ? 'Theek hai' : 'OK'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
