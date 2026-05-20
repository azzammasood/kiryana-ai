import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/language_provider.dart';
import 'package:kiryana_ai/data/models/transaction_model.dart';
import 'package:kiryana_ai/features/logs/providers/transaction_provider.dart';
import '../../../../core/widgets/animated_topbar_logo.dart';
import '../../../../core/widgets/app_widgets.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  const ManualEntryScreen({super.key, this.transactionId});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  bool _isSale = true;
  bool _isEdit = false;
  TransactionModel? _existingTransaction;
  final _itemController = TextEditingController();
  final _amountController = TextEditingController(text: '0');
  final _qtyController = TextEditingController(text: '1');
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _isEdit = widget.transactionId != null;
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingTransaction();
      });
    }
  }

  void _loadExistingTransaction() {
    final transactions = ref.read(transactionsProvider).value ?? [];
    final transaction = transactions.firstWhere((t) => t.id == widget.transactionId);
    setState(() {
      _existingTransaction = transaction;
      _isSale = transaction.isSale;
      _itemController.text = transaction.titleEnglish; // or titleUrdu
      _amountController.text = transaction.amount.toString();
      _qtyController.text = transaction.tag.replaceAll(RegExp(r'[^0-9]'), '');
      _descController.text = ''; // Description not in model yet
      _selectedDate = transaction.date;
    });
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    _qtyController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            surface: AppColors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() async {
    final isUrdu = ref.read(languageProvider).languageCode == 'ur';
    if (_itemController.text.trim().isEmpty) {
      AppToast.show(
        context,
        isUrdu ? 'آئٹم کا نام درج کریں' : 'Please enter item name',
        isError: true,
      );
      return;
    }

    final amount = int.tryParse(_amountController.text) ?? 0;
    final qty = _qtyController.text.isEmpty ? '1' : _qtyController.text;
    
    final transaction = TransactionModel(
      id: _isEdit ? _existingTransaction!.id : const Uuid().v4(),
      titleUrdu: _itemController.text, // For now using same for both
      titleEnglish: _itemController.text,
      tag: '$qty Units',
      date: _selectedDate,
      amount: amount,
      isSale: _isSale,
      iconType: _isSale ? 'sugar' : 'receipt',
    );

    if (_isEdit) {
      await ref.read(transactionsProvider.notifier).updateTransaction(transaction);
    } else {
      await ref.read(transactionsProvider.notifier).addTransaction(transaction);
    }

    if (mounted) {
      AppToast.show(
        context,
        _isSale ? 'فروخت محفوظ ہو گئی!' : 'خرچہ محفوظ ہو گیا!',
      );
      context.pop();
    }
  }

  void _delete() async {
    if (!_isEdit) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ڈیلیٹ کریں؟', textDirection: TextDirection.rtl),
        content: const Text('کیا آپ واقعی اس انٹری کو ڈیلیٹ کرنا چاہتے ہیں؟', textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('کینسل')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('ڈیلیٹ', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(transactionsProvider.notifier).deleteTransaction(_existingTransaction!.id);
      if (mounted) context.pop();
    }
  }

  String _formattedDate() {
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    final y = _selectedDate.year;
    return '$m/$d/$y';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= AppSpacing.mobileBreakpoint;
    final maxW = isWide ? 440.0 : double.infinity;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(languageProvider);
    final isUrdu = locale.languageCode == 'ur';

    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : const Color(0xFFE8EFF2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────
                _buildHeader(isUrdu),

                // ── Scrollable Body ─────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                    children: [
                      _buildToggle(isUrdu),
                      const SizedBox(height: 14),
                      _buildItemNameCard(isUrdu),
                      const SizedBox(height: 12),
                      _buildAmountQtyRow(isUrdu),
                      const SizedBox(height: 12),
                      _buildDateCard(isUrdu),
                      const SizedBox(height: 12),
                      _buildDescriptionCard(isUrdu),
                    ],
                  ),
                ),

                // ── Save/Delete Buttons ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                  child: Column(
                    children: [
                      if (_isEdit) ...[
                        TextButton.icon(
                          onPressed: _delete,
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          label: Text(
                            isUrdu ? 'ڈیلیٹ انٹری (Delete Entry)' : 'Delete Entry',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildSaveButton(isUrdu),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader(bool isUrdu) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 12,
        left: 14,
        right: 14,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            // Badge icon
            const AnimatedTopBarLogo(size: 36),
            const SizedBox(width: 10),
    
            // Title
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _isEdit ? 'Edit Entry' : AppStrings.newEntryEnglish,
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
                        _isEdit ? 'انٹری ایڈٹ کریں' : AppStrings.newEntryUrdu,
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
    
            // Close Button
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: AppColors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggle: Sale / Expense ─────────────────────────────────────────
  Widget _buildToggle(bool isUrdu) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE5E8), width: 1),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          // ── Expense side (LEFT) ─────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSale = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !_isSale ? const Color(0xFFB71C1C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isUrdu)
                      Icon(
                        Icons.remove_circle_outline,
                        size: 22,
                        color: !_isSale ? AppColors.white : AppColors.error,
                      ),
                    if (!isUrdu) const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUrdu)
                          Text(
                            AppStrings.manualExpenseUrdu,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: !_isSale ? AppColors.white : AppColors.textPrimary,
                            ),
                          ),
                        Text(
                          isUrdu ? '(${AppStrings.expenseEnglish})' : AppStrings.expenseEnglish,
                          style: GoogleFonts.inter(
                            fontSize: isUrdu ? 12 : 15,
                            fontWeight: isUrdu ? FontWeight.w500 : FontWeight.w700,
                            color: !_isSale
                                ? AppColors.white
                                : (isUrdu ? AppColors.textSecondary : AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    if (isUrdu) const SizedBox(width: 8),
                    if (isUrdu)
                      Icon(
                        Icons.remove_circle_outline,
                        size: 22,
                        color: !_isSale ? AppColors.white : AppColors.error,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Sale side (RIGHT) ───────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isSale = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isSale ? AppColors.actionGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isUrdu)
                      Icon(
                        Icons.add_circle_outline,
                        size: 22,
                        color: _isSale ? AppColors.white : AppColors.textSecondary,
                      ),
                    if (!isUrdu) const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUrdu)
                          Text(
                            AppStrings.manualSaleUrdu,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _isSale ? AppColors.white : AppColors.textPrimary,
                            ),
                          ),
                        Text(
                          isUrdu ? '(${AppStrings.saleEnglish})' : AppStrings.saleEnglish,
                          style: GoogleFonts.inter(
                            fontSize: isUrdu ? 12 : 15,
                            fontWeight: isUrdu ? FontWeight.w500 : FontWeight.w700,
                            color: _isSale
                                ? AppColors.white
                                : (isUrdu ? AppColors.textSecondary : AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    if (isUrdu) const SizedBox(width: 8),
                    if (isUrdu)
                      Icon(
                        Icons.add_circle_outline,
                        size: 22,
                        color: _isSale ? AppColors.white : AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Item Name Card ────────────────────────────────────────────────
  Widget _buildItemNameCard(bool isUrdu) {
    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUrdu ? AppStrings.itemNameUrdu : AppStrings.itemNameEnglish,
            textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _itemController,
            textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
            decoration: InputDecoration(
              hintText: isUrdu ? AppStrings.itemNameHintUrdu : AppStrings.itemNameHintEnglish,
              hintTextDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDE5E8), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDE5E8), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  // ── Amount + Quantity Row ─────────────────────────────────────────
  Widget _buildAmountQtyRow(bool isUrdu) {
    return Row(
      children: [
        // Quantity (LEFT card — مقدار)
        Expanded(
          child: _cardWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? AppStrings.quantityUrdu : AppStrings.quantityEnglish,
                  textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _qtyController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDDE5E8), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDDE5E8), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Amount (RIGHT card — رقم (Rs))
        Expanded(
          child: _cardWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? AppStrings.manualAmountUrdu : AppStrings.manualAmountEnglish,
                  textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDDE5E8), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDDE5E8), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Date Card ─────────────────────────────────────────────────────
  Widget _buildDateCard(bool isUrdu) {
    return GestureDetector(
      onTap: _pickDate,
      child: _cardWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUrdu ? AppStrings.dateUrdu : AppStrings.dateEnglish,
              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: isUrdu ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isUrdu) const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.textSecondary),
                if (!isUrdu) const SizedBox(width: 8),
                Text(
                  _formattedDate(),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isUrdu) const SizedBox(width: 8),
                if (isUrdu) const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Description Card ──────────────────────────────────────────────
  Widget _buildDescriptionCard(bool isUrdu) {
    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUrdu ? AppStrings.descriptionUrdu : AppStrings.descriptionEnglish,
            textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: isUrdu ? AppStrings.descriptionHintUrdu : AppStrings.descriptionHintEnglish,
              hintTextDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
              filled: true,
              fillColor: AppColors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDE5E8), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDE5E8), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
              ),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Save Button ───────────────────────────────────────────────────
  Widget _buildSaveButton(bool isUrdu) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionGreen,
          foregroundColor: AppColors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.ltr,
          children: [
            const Icon(Icons.save_rounded, size: 22, color: AppColors.white),
            const SizedBox(width: 10),
            Text(
              isUrdu ? AppStrings.saveUrdu : AppStrings.saveEnglish,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared Card Wrapper ───────────────────────────────────────────
  Widget _cardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE5E8), width: 1),
      ),
      child: child,
    );
  }
}
