import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/language_provider.dart';

class LogsAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;

  const LogsAppBar({
    super.key,
    required this.selectedIndex,
    required this.isSearching,
    required this.searchController,
    required this.onSearchToggle,
    required this.onSearchChanged,
  });

  String _getUrduTitle() {
    if (selectedIndex == 1) return AppStrings.weeklyLogUrdu;
    if (selectedIndex == 2) return AppStrings.monthlyLogUrdu;
    return AppStrings.todaysLogUrdu;
  }

  String _getEnglishTitle() {
    if (selectedIndex == 1) return AppStrings.weeklyLogEnglish;
    if (selectedIndex == 2) return AppStrings.monthlyLogEnglish;
    return AppStrings.todaysLogEnglish;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        bottom: AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: isSearching
          ? _buildSearchField(isUrdu)
          : Directionality(
              textDirection: TextDirection.ltr, // Keep layout fixed
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo & Title
                  Expanded(
                    child: Row(
                      children: [
                        Image.asset('assets/images/topbar-logo.png', width: 28, height: 28),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            _getEnglishTitle().replaceAll('(', '').replaceAll(')', ''),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        if (isUrdu) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _getUrduTitle(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Action Icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.memory_rounded, color: AppColors.white, size: 22),
                        tooltip: 'AI System Logs',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          context.push('/ai-logs');
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.search_rounded, color: AppColors.white, size: 22),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: onSearchToggle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchField(bool isUrdu) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: isUrdu ? 'تلاش کریں (Search by title, price, date)...' : 'Search by title, price, date...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.white),
            onPressed: () {
              searchController.clear();
              onSearchChanged('');
              onSearchToggle();
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + AppSpacing.md);
}
