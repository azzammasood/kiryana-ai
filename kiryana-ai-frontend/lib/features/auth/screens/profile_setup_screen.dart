import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../routes/app_router.dart';
import '../../settings/models/profile_model.dart';
import '../../settings/providers/profile_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _storeController = TextEditingController();
  final _locationController = TextEditingController();
  final _ageController = TextEditingController();
  String _plan = 'free';
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController.text = profile.name == 'Kiryana Owner' ? '' : profile.name;
    _storeController.text =
        profile.storeName == 'Kiryana Store' ? '' : profile.storeName;
    _locationController.text = profile.storeLocation;
    _ageController.text = profile.age == 18 ? '' : profile.age.toString();
    _plan = profile.plan;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _storeController.dispose();
    _locationController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    final storeName = _storeController.text.trim();
    final location = _locationController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final current = ref.read(profileProvider);

    if (name.isEmpty || storeName.isEmpty || location.isEmpty || age == null) {
      setState(() => _error = 'Please complete all profile fields');
      return;
    }
    if (age < 13 || age > 100) {
      setState(() => _error = 'Please enter a valid age');
      return;
    }

    final profile = ProfileModel(
      name: name,
      email: current.email,
      phone: current.phone,
      gender: current.gender,
      dob: current.dob,
      description: '$storeName, $location',
      storeName: storeName,
      storeLocation: location,
      age: age,
      plan: _plan,
      profilePicPath: current.profilePicPath,
    );
    await ref.read(profileProvider.notifier).updateProfile(profile);
    if (!mounted) return;
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= AppSpacing.mobileBreakpoint;
    final cardWidth = isWide ? AppSpacing.maxContentWidth : double.infinity;

    // English-only screen: always LTR (Urdu locale would otherwise mirror fields).
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/images/topbar-logo.png', width: 32, height: 32),
            const SizedBox(width: 10),
            Text(
              'Store Profile',
              style: GoogleFonts.inter(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Set up your store',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'This information personalizes reports and store settings.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _field('Owner name', _nameController, Icons.person_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _field('Store name', _storeController, Icons.store_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _field('Store location', _locationController,
                        Icons.location_on_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _field(
                      'Owner age',
                      _ageController,
                      Icons.cake_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _mapPreview(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Plan',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _planCard(
                            title: 'Free',
                            subtitle: 'Standard AI sessions',
                            selected: _plan == 'free',
                            onTap: () => setState(() => _plan = 'free'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _planCard(
                            title: 'Premium',
                            subtitle: 'Unlimited AI sessions',
                            selected: _plan == 'premium',
                            premium: true,
                            onTap: () => setState(() => _plan = 'premium'),
                          ),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.actionGreen,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    const fieldStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      style: fieldStyle,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _mapPreview() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight,
            AppColors.primary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 22,
            child: Container(width: 120, height: 8, color: AppColors.white),
          ),
          Positioned(
            right: 18,
            bottom: 24,
            child: Container(width: 150, height: 8, color: AppColors.white),
          ),
          const Center(
            child: Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 46,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    bool premium = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? (premium ? const Color(0xFFC99922) : AppColors.primary)
                : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              premium ? Icons.workspace_premium_rounded : Icons.check_circle,
              color: premium ? const Color(0xFFC99922) : AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
