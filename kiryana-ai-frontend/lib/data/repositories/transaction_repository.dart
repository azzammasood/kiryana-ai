import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../mock/mock_logs_data.dart';

/// Abstract repository defining transaction operations.
abstract class TransactionRepository {
  Future<List<TransactionModel>> getTransactions();
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}

/// Mock implementation of [TransactionRepository] for development and testing.
class MockTransactionRepository implements TransactionRepository {
  static const String _storageKey = 'kiryana_transactions';
  final List<TransactionModel> _transactions = [];
  bool _initialized = false;

  MockTransactionRepository() {
    // Initialized asynchronously
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    
    if (jsonStr != null) {
      final List<dynamic> decoded = json.decode(jsonStr);
      _transactions.addAll(decoded.map((item) => TransactionModel.fromJson(item as Map<String, dynamic>)));
    }
    
    if (_transactions.isEmpty) {
      _seedData();
      await _saveToPrefs();
    }
    _initialized = true;
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_transactions.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  void _seedData() {
    final now = DateTime.now();

    DateTime makeDate(int daysAgo, String timeStr) {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      if (parts.length > 1 && parts[1] == 'PM' && hour < 12) hour += 12;
      if (parts.length > 1 && parts[1] == 'AM' && hour == 12) hour = 0;

      final date = now.subtract(Duration(days: daysAgo));
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    // Add explicit items for Today and Yesterday from the dailyLogItems
    for (var item in MockLogsData.dailyLogItems) {
      final daysAgo = int.tryParse(item.id) != null && int.parse(item.id) <= 4 ? 0 : 1;
      _transactions.add(TransactionModel(
        id: item.id,
        titleUrdu: item.titleUrdu,
        titleEnglish: item.titleEnglish,
        tag: item.tag,
        date: makeDate(daysAgo, item.time),
        amount: item.amount,
        isSale: item.isSale,
        iconType: item.iconType,
      ));
    }

    // Generate random but realistic data for days 2 to 30 to fully populate the weekly and monthly charts
    int mockIdCounter = 100;
    final tags = ['Groc', 'Bill', 'Snack', 'Misc'];
    for (int daysAgo = 2; daysAgo <= 30; daysAgo++) {
      // Sales
      _transactions.add(TransactionModel(
        id: '${mockIdCounter++}',
        titleUrdu: 'عام فروخت',
        titleEnglish: 'General Sale',
        tag: tags[daysAgo % tags.length],
        date: makeDate(daysAgo, '10:30 AM'),
        amount: 400 + (daysAgo % 5 * 100),
        isSale: true,
        iconType: 'sale',
      ));
      
      // Every 3rd day, let's have a large expense to show a red bar (loss)
      if (daysAgo % 3 == 0) {
        _transactions.add(TransactionModel(
          id: '${mockIdCounter++}',
          titleUrdu: 'بڑے اخراجات',
          titleEnglish: 'Stock / Rent',
          tag: 'Expense',
          date: makeDate(daysAgo, '02:00 PM'),
          amount: 2500 + (daysAgo % 10 * 100),
          isSale: false,
          iconType: 'bill',
        ));
      } else {
        // Normal small expense
        _transactions.add(TransactionModel(
          id: '${mockIdCounter++}',
          titleUrdu: 'متفرق اخراجات',
          titleEnglish: 'Misc Expense',
          tag: 'Expense',
          date: makeDate(daysAgo, '04:00 PM'),
          amount: 100 + (daysAgo % 3 * 50),
          isSale: false,
          iconType: 'misc',
        ));
      }
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_transactions);
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    _transactions.insert(0, transaction);
    await _saveToPrefs();
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      await _saveToPrefs();
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));
    _transactions.removeWhere((t) => t.id == id);
    await _saveToPrefs();
  }
}
