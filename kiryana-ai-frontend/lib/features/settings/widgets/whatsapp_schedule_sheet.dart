import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

Future<({String day, String time, bool enabled})?> showWhatsAppScheduleSheet({
  required BuildContext context,
  required bool isUrdu,
  required String initialDay,
  required String initialTime,
  required bool notificationsEnabled,
}) {
  return showModalBottomSheet<({String day, String time, bool enabled})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _WhatsAppScheduleSheet(
      isUrdu: isUrdu,
      initialDay: initialDay,
      initialTime: initialTime,
      notificationsEnabled: notificationsEnabled,
    ),
  );
}

class _WhatsAppScheduleSheet extends StatefulWidget {
  final bool isUrdu;
  final String initialDay;
  final String initialTime;
  final bool notificationsEnabled;

  const _WhatsAppScheduleSheet({
    required this.isUrdu,
    required this.initialDay,
    required this.initialTime,
    required this.notificationsEnabled,
  });

  @override
  State<_WhatsAppScheduleSheet> createState() => _WhatsAppScheduleSheetState();
}

class _WhatsAppScheduleSheetState extends State<_WhatsAppScheduleSheet> {
  late String _selectedDay;
  late TimeOfDay _selectedTime;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _selectedDay = _weekdays.contains(widget.initialDay)
        ? widget.initialDay
        : 'Sunday';
    _selectedTime = _parseTime(widget.initialTime);
    _enabled = widget.notificationsEnabled;
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]) ?? 10;
      final m = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    }
    return const TimeOfDay(hour: 10, minute: 0);
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = widget.isUrdu;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/whatsapp-icon.png',
                width: 36,
                height: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isUrdu ? 'واٹس ایپ رپورٹ شیڈول' : 'WhatsApp report schedule',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isUrdu
                ? 'Hafte ki report kis din aur kis waqt bhejni hai choose karen.'
                : 'Choose which day and time to receive your weekly report.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              isUrdu ? 'رپورٹ فعال' : 'Reports enabled',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            value: _enabled,
            activeTrackColor: const Color(0xFF25D366),
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: 8),
          Text(
            isUrdu ? 'دن' : 'Day of week',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekdays.map((day) {
              final selected = _selectedDay == day;
              final short = day.substring(0, 3);
              return ChoiceChip(
                label: Text(short),
                selected: selected,
                onSelected: (_) => setState(() => _selectedDay = day),
                selectedColor: const Color(0xFF25D366).withValues(alpha: 0.25),
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            isUrdu ? 'وقت' : 'Time',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    _formatTime(_selectedTime),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isUrdu ? 'تبدیل' : 'Change',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                (
                  day: _selectedDay,
                  time: _formatTime(_selectedTime),
                  enabled: _enabled,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isUrdu ? 'محفوظ کریں' : 'Save schedule',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
