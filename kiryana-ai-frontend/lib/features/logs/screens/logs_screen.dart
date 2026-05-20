import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../dashboard/widgets/custom_bottom_nav.dart';
import 'package:kiryana_ai/data/models/transaction_model.dart';
import 'package:kiryana_ai/features/logs/providers/transaction_provider.dart';
import '../widgets/logs_app_bar.dart';
import '../widgets/time_filter_tabs.dart';
import '../widgets/date_separator.dart';
import '../widgets/transaction_card.dart';
import '../../../core/providers/language_provider.dart';

class LogGroup {
  final String date;
  final List<TransactionModel> items;

  const LogGroup({required this.date, required this.items});
}

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  int _currentIndex = 1; // 1 is for Logs tab
  int _selectedTabIndex = 0; // 0: Daily, 1: Weekly, 2: Monthly

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    if (index == 0) {
      context.go('/dashboard');
    } else if (index == 2) {
      context.go('/insights');
    } else if (index == 3) {
      context.go('/settings');
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _onFabTap() {
    context.push('/manual-entry');
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= AppSpacing.mobileBreakpoint;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : AppColors.secondary,
      appBar: LogsAppBar(
        selectedIndex: _selectedTabIndex,
        isSearching: _isSearching,
        searchController: _searchController,
        onSearchToggle: () => setState(() {
          _isSearching = !_isSearching;
          if (!_isSearching) {
            _searchQuery = '';
            _searchController.clear();
          }
        }),
        onSearchChanged: (val) => setState(() => _searchQuery = val),
      ),
      body: SafeArea(
        child: transactionsAsync.when(
          loading: () => _buildSkeletonLoader(isWide),
          error: (err, stack) => Center(
              child: Text('Error: $err',
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black))),
          data: (transactions) {
            final groups = _getGroupedLogs(transactions);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      isWide ? AppSpacing.maxContentWidth : double.infinity,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    TimeFilterTabs(
                      selectedIndex: _selectedTabIndex,
                      onChanged: (index) =>
                          setState(() => _selectedTabIndex = index),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        children: [
                          if (groups.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_rounded,
                                      size: 64,
                                      color: (isDark
                                              ? AppColors.white
                                              : AppColors.textHint)
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  if (isUrdu)
                                    Text(
                                      'کوئی انٹری نہیں ملی',
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  if (isUrdu) const SizedBox(height: 4),
                                  Text(
                                    'No transactions found.',
                                    style: GoogleFonts.inter(
                                      fontSize: isUrdu ? 13 : 18,
                                      fontWeight: isUrdu
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      color: isDark
                                          ? AppColors.white
                                          : (isUrdu
                                              ? AppColors.textHint
                                              : AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...groups.map((group) => Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    DateSeparator(date: group.date),
                                    ...group.items
                                        .map((item) => GestureDetector(
                                              onTap: () => context.push(
                                                  '/manual-entry/${item.id}'),
                                              child:
                                                  TransactionCard(item: item),
                                            )),
                                  ],
                                )),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabTap,
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? BorderSide(
                  color: AppColors.white.withValues(alpha: 0.3), width: 1.2)
              : BorderSide.none,
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.white, size: 32),
      ),
      floatingActionButtonLocation: const FixedEndFloatFabLocation(),
      bottomNavigationBar: isWide
          ? null
          : CustomBottomNav(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
    );
  }

  List<LogGroup> _getGroupedLogs(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    // 1. Filter based on tab and search query
    final filtered = transactions.where((t) {
      // Tab Filtering
      bool matchesTab = false;
      if (_selectedTabIndex == 0) {
        // Daily: Today Only
        matchesTab = t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day;
      } else if (_selectedTabIndex == 1) {
        // Weekly: Last 7 days
        final weekAgo = startOfToday.subtract(const Duration(days: 7));
        matchesTab =
            t.date.isAfter(weekAgo) || t.date.isAtSameMomentAs(weekAgo);
      } else {
        // Monthly: Last 30 days
        final monthAgo = startOfToday.subtract(const Duration(days: 30));
        matchesTab =
            t.date.isAfter(monthAgo) || t.date.isAtSameMomentAs(monthAgo);
      }

      if (!matchesTab) return false;

      // Search Filtering
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = t.titleEnglish.toLowerCase().contains(query) ||
            t.titleUrdu.toLowerCase().contains(query);
        final matchesPrice = t.amount.toString().contains(query);
        final dateStr = _formatDateKey(t.date).toLowerCase();
        final matchesDate = dateStr.contains(query);

        if (!matchesTitle && !matchesPrice && !matchesDate) return false;
      }

      return true;
    }).toList();

    // 2. Sort items descending by date/time (newest on top)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    // 3. Group by date string
    final groupedMap = <String, List<TransactionModel>>{};
    for (var t in filtered) {
      final dateKey = _formatDateKey(t.date);
      groupedMap.putIfAbsent(dateKey, () => []).add(t);
    }

    // 4. Convert to LogGroup list and sort groups descending by their newest item's date
    final groups = groupedMap.entries
        .map((e) => LogGroup(date: e.key, items: e.value))
        .toList();
    groups.sort((a, b) => b.items.first.date.compareTo(a.items.first.date));
    return groups;
  }

  String _formatDateKey(DateTime date) {
    final isUrdu = ref.read(languageProvider).languageCode == 'ur';
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return isUrdu ? 'آج' : 'Today (${DateFormat('dd MMMM').format(date)})';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return isUrdu
          ? 'کل'
          : 'Yesterday (${DateFormat('dd MMMM').format(date)})';
    }
    return DateFormat('dd MMMM, yyyy').format(date);
  }

  Widget _buildSkeletonLoader(bool isWide) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWide ? AppSpacing.maxContentWidth : double.infinity,
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xl),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 12,
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class FixedEndFloatFabLocation extends FloatingActionButtonLocation {
  const FixedEndFloatFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Always place on the right regardless of LTR/RTL
    final double fabX = scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        20; // Slightly more margin

    // Position fabY slightly above the bottom content area (usually where nav bar starts)
    final double fabY = scaffoldGeometry.contentBottom -
        scaffoldGeometry.floatingActionButtonSize.height -
        20; // Margin from bottom nav or bottom of screen

    return Offset(fabX, fabY);
  }
}
