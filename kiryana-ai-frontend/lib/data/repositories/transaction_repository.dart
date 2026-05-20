import '../../core/services/api_service.dart';
import '../models/transaction_model.dart';

abstract class TransactionRepository {
  Future<List<TransactionModel>> getTransactions();
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}

class ApiTransactionRepository implements TransactionRepository {
  final ApiService _api;

  ApiTransactionRepository({ApiService? api}) : _api = api ?? ApiService();

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final userId = await _api.currentUserId();
    final rows = await _api.getTransactions(userId, filter: 'month');
    return rows
        .map((item) =>
            TransactionModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final userId = await _api.currentUserId();
    await _api.saveTransaction(transaction.toApiJson(userId));
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await deleteTransaction(transaction.id);
    await addTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _api.deleteTransaction(id);
  }
}
