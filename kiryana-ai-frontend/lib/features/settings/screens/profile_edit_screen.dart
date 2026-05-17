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
import '../../../../core/widgets/app_widgets.dart';

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
    _selectedGender = profile.gender;
    _profilePicPath = profile.profilePicPath;
    
    // Parse DOB string if possible (e.g. 15/05/1990)
    try {
      final parts = profile.dob.split('/');
      if (parts.length == 3) {
        _selectedDob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
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
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final updatedProfile = ref.read(profileProvider).copyWith(
      name: _nameController.text,
      email: _emailController.text,
      gender: _selectedGender,
      dob: _selectedDob != null ? '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}' : '',
      description: _workDescController.text,
      profilePicPath: _profilePicPath,
    );

    await ref.read(profileProvider.notifier).updateProfile(updatedProfile);

    if (mounted) {
      Navigator.pop(context); // Close dialog
      AppToast.show(
        context,
        isUrdu ? 'پروفائل کامیابی کے ساتھ اپ ڈیٹ ہو گئی!' : 'Profile updated successfully!',
      );
      context.pop(); // Go back
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimary,
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

    return Scaffold(
      backgroundColor: AppColors.secondary,
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
              isUrdu ? 'پروفائل تبدیل کریں (Edit Profile)' : 'Edit Profile',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white),
            ),
            actions: [
              TextButton(
                onPressed: _onSave,
                child: Text(
                  'Save',
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16),
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
            // Profile Picture
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        image: _profilePicPath != null
                            ? DecorationImage(
                                image: kIsWeb 
                                    ? NetworkImage(_profilePicPath!) 
                                    : FileImage(File(_profilePicPath!)) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profilePicPath == null
                          ? const Icon(Icons.person_rounded, size: 60, color: AppColors.primary)
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
                        child: const Icon(Icons.camera_alt_rounded, size: 20, color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Form Fields
            _buildTextField(isUrdu ? 'نام (Name)' : 'Name', _nameController, isUrdu),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(isUrdu ? 'ای میل (Email)' : 'Email', _emailController, isUrdu, TextInputType.emailAddress),
            const SizedBox(height: AppSpacing.md),
            
            // Gender Dropdown
            _buildLabel(isUrdu ? 'صنف (Gender)' : 'Gender', isUrdu),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGender,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                  items: ['Male', 'Female', 'Other'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: GoogleFonts.inter(color: AppColors.textPrimary)),
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
            
            // DOB Picker
            _buildLabel(isUrdu ? 'تاریخ پیدائش (Date of Birth)' : 'Date of Birth', isUrdu),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDob == null ? (isUrdu ? 'Select Date' : 'Select Date') : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                      style: GoogleFonts.inter(
                        color: _selectedDob == null ? AppColors.textHint : AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            _buildTextField(isUrdu ? 'کاروبار کی تفصیل (Work Description)' : 'Work Description', _workDescController, isUrdu, TextInputType.multiline, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isUrdu) {
    return Align(
      alignment: isUrdu ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isUrdu, [TextInputType type = TextInputType.text, int maxLines = 1]) {
    return Column(
      crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isUrdu),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: type,
          maxLines: maxLines,
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          textAlign: isUrdu ? TextAlign.right : TextAlign.left,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
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
