import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/profile_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../routes/app_router.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _workDescController;

  String _selectedGender = 'Male';
  DateTime? _selectedDob;
  String? _profilePicPath;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _workDescController = TextEditingController(text: profile.description);
    _selectedGender = profile.gender.isNotEmpty ? profile.gender : 'Male';
    _profilePicPath = profile.profilePicPath;

    try {
      final parts = profile.dob.split('/');
      if (parts.length == 3) {
        _selectedDob = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _workDescController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final isUrdu = ref.read(languageProvider).languageCode == 'ur';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final updatedProfile = ref.read(profileProvider).copyWith(
          name: _nameController.text,
          email: _emailController.text,
          gender: _selectedGender,
          dob: _selectedDob != null
              ? '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}'
              : '',
          description: _workDescController.text,
          profilePicPath: _profilePicPath,
        );

    await ref.read(profileProvider.notifier).updateProfile(updatedProfile);

    if (mounted) {
      Navigator.pop(context);
      AppToast.show(
        context,
        isUrdu
            ? 'پروفائل کامیابی کے ساتھ اپ ڈیٹ ہو گئی!'
            : 'Profile updated successfully!',
      );
      context.pop();
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profilePicPath = image.path;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDark) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final profile = ref.watch(profileProvider);

    final bg = isDark ? AppColors.primary : AppColors.secondary;
    final fieldBg = isDark ? AppColors.darkCard : AppColors.white;
    final fieldBorder =
        isDark ? AppColors.darkBorder : AppColors.border;
    final labelColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final hintColor =
        isDark ? AppColors.white.withValues(alpha: 0.45) : AppColors.textHint;

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
              onPressed: () => context.pop(),
            ),
            title: Text(
              isUrdu ? 'پروفائل' : 'Edit Profile',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            actions: [
              TextButton(
                onPressed: _onSave,
                child: Text(
                  isUrdu ? 'محفوظ' : 'Save',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                        image: _profilePicPath != null
                            ? DecorationImage(
                                image: kIsWeb
                                    ? NetworkImage(_profilePicPath!)
                                    : FileImage(File(_profilePicPath!))
                                        as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profilePicPath == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 60,
                              color: isDark
                                  ? AppColors.white.withValues(alpha: 0.7)
                                  : AppColors.primary,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 20,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildPhoneCard(
              isUrdu: isUrdu,
              phone: profile.phone,
              fieldBg: fieldBg,
              fieldBorder: fieldBorder,
              labelColor: labelColor,
              textColor: textColor,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              isUrdu ? 'نام' : 'Name',
              _nameController,
              isUrdu,
              fieldBg: fieldBg,
              fieldBorder: fieldBorder,
              labelColor: labelColor,
              textColor: textColor,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              isUrdu ? 'ای میل' : 'Email',
              _emailController,
              isUrdu,
              fieldBg: fieldBg,
              fieldBorder: fieldBorder,
              labelColor: labelColor,
              textColor: textColor,
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildLabel(isUrdu ? 'صنف' : 'Gender', isUrdu, labelColor),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: fieldBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGender,
                  isExpanded: true,
                  dropdownColor: fieldBg,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: labelColor),
                  items: ['Male', 'Female', 'Other'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: GoogleFonts.inter(color: textColor),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedGender = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildLabel(isUrdu ? 'تاریخ پیدائش' : 'Date of Birth', isUrdu, labelColor),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () => _selectDate(context, isDark),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: fieldBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDob == null
                          ? (isUrdu ? 'تاریخ منتخب کریں' : 'Select date')
                          : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                      style: GoogleFonts.inter(
                        color: _selectedDob == null ? hintColor : textColor,
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.calendar_today_rounded, color: labelColor, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              isUrdu ? 'کاروبار کی تفصیل' : 'Work Description',
              _workDescController,
              isUrdu,
              fieldBg: fieldBg,
              fieldBorder: fieldBorder,
              labelColor: labelColor,
              textColor: textColor,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneCard({
    required bool isUrdu,
    required String phone,
    required Color fieldBg,
    required Color fieldBorder,
    required Color labelColor,
    required Color textColor,
  }) {
    final displayPhone = phone.trim().isEmpty
        ? (isUrdu ? 'فون نمبر محفوظ نہیں' : 'No phone number saved')
        : phone;

    return Column(
      crossAxisAlignment:
          isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _buildLabel(isUrdu ? 'فون نمبر' : 'Phone number', isUrdu, labelColor),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.phone_android_rounded, color: labelColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayPhone,
                  textDirection: TextDirection.ltr,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.changePhone),
                child: Text(
                  isUrdu ? 'تبدیل' : 'Change',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, bool isUrdu, Color color) {
    return Align(
      alignment: isUrdu ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isUrdu, {
    required Color fieldBg,
    required Color fieldBorder,
    required Color labelColor,
    required Color textColor,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment:
          isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isUrdu, labelColor),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          textAlign: isUrdu ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.inter(color: textColor, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
