import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/hive_service.dart';
import '../models/transaction.dart';

class TransactionProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  List<Transaction> _transactions = [];
  String _searchQuery = '';
  TransactionType? _filterType;
  DateTime? _filterStart;
  DateTime? _filterEnd;

  /// The active account to scope all queries to
  String _activeAccountId = '';

  List<Transaction> get transactions => _transactions;
  String get searchQuery => _searchQuery;
  TransactionType? get filterType => _filterType;
  String get activeAccountId => _activeAccountId;

  TransactionProvider() {
    loadTransactions();
  }

  void setActiveAccount(String accountId) {
    _activeAccountId = accountId;
    loadTransactions();
  }

  void loadTransactions() {
    if (_activeAccountId.isNotEmpty) {
      _transactions = HiveService.getTransactionsForAccount(_activeAccountId);
    } else {
      _transactions = HiveService.getAllTransactions();
    }
    notifyListeners();
  }

  /// All transactions across all accounts (for combined savings)
  List<Transaction> get allTransactions => HiveService.getAllTransactions();

  List<Transaction> get filteredTransactions {
    var list = _transactions;
    if (_filterType != null) {
      list = list.where((t) => t.type == _filterType).toList();
    }
    if (_filterStart != null) {
      list = list
          .where((t) =>
              t.date.isAfter(_filterStart!.subtract(const Duration(days: 1))))
          .toList();
    }
    if (_filterEnd != null) {
      list = list
          .where((t) =>
              t.date.isBefore(_filterEnd!.add(const Duration(days: 1))))
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((t) =>
              t.note.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q) ||
              t.source.toLowerCase().contains(q) ||
              t.amount.toString().contains(q))
          .toList();
    }
    return list;
  }

  List<Transaction> get recentTransactions {
    return _transactions.take(10).toList();
  }

  // ── Totals for current month (active account) ─────────────────
  double get currentMonthIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get currentMonthExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0, (sum, t) => sum + t.amount);
  }

  /// Current month balance: income − expense for this month, this account
  double get currentMonthBalance => currentMonthIncome - currentMonthExpense;

  /// Net savings for the active account (all-time income − all-time expense)
  /// This is NOT double-counted; it's a pure calculation from raw transactions
  double get accountNetSavings {
    double income = _transactions.fold(
        0, (s, t) => t.type == TransactionType.income ? s + t.amount : s);
    double expense = _transactions.fold(
        0, (s, t) => t.type == TransactionType.expense ? s + t.amount : s);
    return income - expense;
  }

  /// Combined net savings across ALL accounts
  double get combinedNetSavings {
    final all = HiveService.getAllTransactions();
    double income =
        all.fold(0, (s, t) => t.type == TransactionType.income ? s + t.amount : s);
    double expense =
        all.fold(0, (s, t) => t.type == TransactionType.expense ? s + t.amount : s);
    return income - expense;
  }

  // ── CRUD ──────────────────────────────────────────────────────
  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required String category,
    required String source,
    String note = '',
    required DateTime date,
    required String time,
    String? accountId,
  }) async {
    final tx = Transaction(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      category: category,
      source: source,
      note: note,
      date: date,
      time: time,
      createdAt: DateTime.now(),
      accountId: accountId ?? _activeAccountId,
    );
    await HiveService.addTransaction(tx);
    loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await HiveService.deleteTransaction(id);
    loadTransactions();
  }

  Future<void> updateTransaction(Transaction tx) async {
    await HiveService.updateTransaction(tx);
    loadTransactions();
  }

  // ── Filters ───────────────────────────────────────────────────
  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterType(TransactionType? type) {
    _filterType = type;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _filterStart = start;
    _filterEnd = end;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterType = null;
    _filterStart = null;
    _filterEnd = null;
    notifyListeners();
  }

  // ── Analytics ─────────────────────────────────────────────────
  Map<String, double> getExpenseBreakdown({int? month, int? year}) {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;
    final Map<String, double> breakdown = {};
    for (final t in _transactions) {
      if (t.type == TransactionType.expense &&
          t.date.month == m &&
          t.date.year == y) {
        breakdown[t.category] = (breakdown[t.category] ?? 0) + t.amount;
      }
    }
    return breakdown;
  }

  Map<String, double> getIncomeBreakdown({int? month, int? year}) {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;
    final Map<String, double> breakdown = {};
    for (final t in _transactions) {
      if (t.type == TransactionType.income &&
          t.date.month == m &&
          t.date.year == y) {
        breakdown[t.source] = (breakdown[t.source] ?? 0) + t.amount;
      }
    }
    return breakdown;
  }

  List<Map<String, dynamic>> getLast6MonthsData() {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final month = now.month - i;
      final year = month <= 0 ? now.year - 1 : now.year;
      final adjustedMonth = month <= 0 ? month + 12 : month;
      double income = 0;
      double expense = 0;
      for (final t in _transactions) {
        if (t.date.month == adjustedMonth && t.date.year == year) {
          if (t.type == TransactionType.income) {
            income += t.amount;
          } else {
            expense += t.amount;
          }
        }
      }
      result.add({'month': adjustedMonth, 'year': year, 'income': income, 'expense': expense});
    }
    return result;
  }
}
