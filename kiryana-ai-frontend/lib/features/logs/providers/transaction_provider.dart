import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/insight_refresh_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

/// Provider for the [TransactionRepository].
/// Using a singleton so Add/Edit/Delete actually persists across reads.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return ApiTransactionRepository();
});

/// AsyncNotifier provider for managing the list of transactions.
final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(() {
  return TransactionsNotifier();
});

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  FutureOr<List<TransactionModel>> build() async {
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.getTransactions();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.addTransaction(transaction);
      final userId = await ApiService().currentUserId();
      await ApiService().refreshInsightsAfterTransaction(userId);
      ref.read(insightRefreshProvider.notifier).state++;
      return repo.getTransactions();
    });
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.updateTransaction(transaction);
      return repo.getTransactions();
    });
  }

  Future<void> deleteTransaction(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.deleteTransaction(id);
      return repo.getTransactions();
    });
  }
}

// ── Derived Statistics Providers ──────────────────────────────────────────

/// Provides the total sales amount for today.
final todaySalesProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();

  return transactions
      .where((t) =>
          t.isSale &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day)
      .fold(0, (sum, t) => sum + t.amount);
});

/// Provides the total expense amount for today.
final todayExpensesProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();

  return transactions
      .where((t) =>
          !t.isSale &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day)
      .fold(0, (sum, t) => sum + t.amount);
});

/// Provides the total items sold today.
final todayItemsCountProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();

  return transactions
      .where((t) =>
          t.isSale &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day)
      .length;
});

/// Provides a list of top selling items based on frequency.
final topSellingItemsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];

  final sales = transactions.where((t) => t.isSale);
  final counts = <String, int>{};
  final namesUrdu = <String, String>{};

  for (var sale in sales) {
    counts[sale.titleEnglish] = (counts[sale.titleEnglish] ?? 0) + 1;
    namesUrdu[sale.titleEnglish] = sale.titleUrdu;
  }

  final sortedKeys = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

  return sortedKeys
      .take(3)
      .map((key) => {
            'name': key,
            'nameUrdu': namesUrdu[key],
            'count': counts[key],
            'progress': 0.7 + (0.1 * (3 - sortedKeys.indexOf(key))),
          })
      .toList();
});

/// Data model for a single day's bar in the weekly chart.
class DayChartData {
  final String label;
  final int income;
  final int expense;
  final bool isToday;

  const DayChartData({
    required this.label,
    this.income = 0,
    this.expense = 0,
    this.isToday = false,
  });

  /// Net = income - expense. Positive means profit, negative means loss.
  int get net => income - expense;
}

/// Provides chart data for the last 7 days, calculated from real transactions.
/// Each bar represents (income - expense) for that day.
/// The last bar is always today.
final weeklyChartDataProvider = Provider<List<DayChartData>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<DayChartData> result = [];

  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final dayTransactions = transactions.where((t) =>
        t.date.year == day.year &&
        t.date.month == day.month &&
        t.date.day == day.day);

    final income = dayTransactions
        .where((t) => t.isSale)
        .fold(0, (sum, t) => sum + t.amount);
    final expense = dayTransactions
        .where((t) => !t.isSale)
        .fold(0, (sum, t) => sum + t.amount);

    result.add(DayChartData(
      label: dayLabels[day.weekday - 1],
      income: income,
      expense: expense,
      isToday: i == 0,
    ));
  }

  return result;
});

/// Weekly totals for Insights summary bars.
final weeklySalesProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));

  return transactions
      .where((t) => t.isSale && t.date.isAfter(weekAgo))
      .fold(0, (sum, t) => sum + t.amount);
});

final weeklyExpensesProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));

  return transactions
      .where((t) => !t.isSale && t.date.isAfter(weekAgo))
      .fold(0, (sum, t) => sum + t.amount);
});
