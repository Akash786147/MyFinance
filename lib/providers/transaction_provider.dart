import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../providers/budget_provider.dart';
import 'package:provider/provider.dart';

enum TransactionFilter { all, income, expense, recurring }

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  BudgetProvider? _budgetProvider;
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  DateTime _selectedMonth = DateTime.now();
  Map<String, double> _categoryTotals = {};
  double _totalIncome = 0;
  double _totalExpense = 0;
  TransactionFilter _currentFilter = TransactionFilter.all;

  // Getters
  List<Transaction> get transactions => _filteredTransactions;
  DateTime get selectedMonth => _selectedMonth;
  Map<String, double> get categoryTotals => _categoryTotals;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  TransactionFilter get currentFilter => _currentFilter;

  // Setter for BudgetProvider
  void setBudgetProvider(BudgetProvider provider) {
    _budgetProvider = provider;
  }

  Future<void> init() async {
    await selectMonth(_selectedMonth);
  }

  Future<void> selectMonth(DateTime date) async {
    _selectedMonth = DateTime(date.year, date.month, 1);
    await _loadTransactionsForSelectedMonth();
    _applyFilter(_currentFilter);
    notifyListeners();
  }

  void setFilter(TransactionFilter filter) {
    _currentFilter = filter;
    _applyFilter(filter);
    notifyListeners();
  }

  void _applyFilter(TransactionFilter filter) {
    switch (filter) {
      case TransactionFilter.all:
        _filteredTransactions = List.from(_transactions);
        break;
      case TransactionFilter.income:
        _filteredTransactions = _transactions
            .where((t) => t.type == TransactionType.income)
            .toList();
        break;
      case TransactionFilter.expense:
        _filteredTransactions = _transactions
            .where((t) => t.type == TransactionType.expense)
            .toList();
        break;
      case TransactionFilter.recurring:
        _filteredTransactions =
            _transactions.where((t) => t.isRecurring).toList();
        break;
    }
  }

  Future<void> _loadTransactionsForSelectedMonth() async {
    try {
      // Get transactions from database for the selected month
      var transactions =
          await _databaseService.getTransactionsByMonth(_selectedMonth);

      // Cast the dynamic list to List<Transaction>
      _transactions = transactions.cast<Transaction>();
      _filteredTransactions = List.from(_transactions);

      // Calculate totals and category expenses
      _calculateTotals();
    } catch (e) {
      print('Error loading transactions: $e');
      rethrow;
    }
  }

  Future<void> _calculateTotals() async {
    _totalIncome = 0;
    _totalExpense = 0;
    _categoryTotals = {};

    for (var transaction in _transactions) {
      if (transaction.type == TransactionType.income) {
        _totalIncome += transaction.amount;
      } else {
        _totalExpense += transaction.amount;

        // Calculate category totals for expenses
        if (_categoryTotals.containsKey(transaction.categoryId)) {
          _categoryTotals[transaction.categoryId] =
              (_categoryTotals[transaction.categoryId] ?? 0) +
                  transaction.amount;
        } else {
          _categoryTotals[transaction.categoryId] = transaction.amount;
        }
      }
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      // Insert into database
      await _databaseService.insertTransaction(transaction);

      // Schedule notification if recurring
      if (transaction.isRecurring) {
        await _notificationService.scheduleNotification(transaction);
      }

      // Refresh data
      await _refreshData();

      // Check budget threshold if it's an expense
      if (transaction.type == TransactionType.expense && _budgetProvider != null) {
        await _budgetProvider!.checkBudgetThreshold(_totalExpense);
      }
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      // Update in database
      await _databaseService.updateTransaction(transaction);

      // Handle notification updates
      if (transaction.isRecurring) {
        await _notificationService.scheduleNotification(transaction);
      } else {
        await _notificationService.cancelNotification(transaction);
      }

      // Refresh data
      await _refreshData();

      // Check budget threshold if it's an expense
      if (transaction.type == TransactionType.expense && _budgetProvider != null) {
        await _budgetProvider!.checkBudgetThreshold(_totalExpense);
      }
    } catch (e) {
      print('Error updating transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final transaction = await _databaseService.getTransactionById(id);
      await _databaseService.deleteTransaction(id);

      if (transaction.isRecurring) {
        await _notificationService.cancelNotification(transaction);
      }

      await _refreshData();

      // Check budget threshold if it was an expense
      if (transaction.type == TransactionType.expense && _budgetProvider != null) {
        await _budgetProvider!.checkBudgetThreshold(_totalExpense);
      }
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  Future<void> _refreshData() async {
    await _loadTransactionsForSelectedMonth();
    _applyFilter(_currentFilter);
    notifyListeners();
  }

  // Get total income for the selected month
  Future<double> getTotalIncome() async {
    return await _databaseService.getTotalForPeriod(
        _selectedMonth, TransactionType.income);
  }

  // Get total expenses for the selected month
  Future<double> getTotalExpenses() async {
    return await _databaseService.getTotalForPeriod(
        _selectedMonth, TransactionType.expense);
  }

  // Get expenses grouped by category for the selected month
  Future<Map<String, double>> getCategoryExpenses() async {
    return await _databaseService.getCategoryTotals(
        _selectedMonth, TransactionType.expense);
  }

  // Public method to refresh transactions data
  Future<void> loadTransactions() async {
    await _loadTransactionsForSelectedMonth();
    _applyFilter(_currentFilter);
    notifyListeners();
  }
}
