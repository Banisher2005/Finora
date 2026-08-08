import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/monthly_report.dart';
import '../models/account.dart';
import '../models/lending.dart';

class HiveService {
  static const String _transactionsBox = 'transactions';
  static const String _reportsBox = 'monthly_reports';
  static const String _accountsBox = 'accounts';
  static const String _lendingBox = 'lending';
  static const _uuid = Uuid();

  static Box<Transaction> get transactions =>
      Hive.box<Transaction>(_transactionsBox);

  static Box<MonthlyReport> get reports =>
      Hive.box<MonthlyReport>(_reportsBox);

  static Box<Account> get accounts => Hive.box<Account>(_accountsBox);

  static Box<LendingEntry> get lending => Hive.box<LendingEntry>(_lendingBox);

  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(MonthlyReportAdapter());
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(LendingDirectionAdapter());
    Hive.registerAdapter(LendingEntryAdapter());
    await Hive.openBox<Transaction>(_transactionsBox);
    await Hive.openBox<MonthlyReport>(_reportsBox);
    await Hive.openBox<Account>(_accountsBox);
    await Hive.openBox<LendingEntry>(_lendingBox);
    await _ensureDefaultAccounts();
  }

  // ── Accounts ─────────────────────────────────────────────────
  static Future<void> _ensureDefaultAccounts() async {
    if (!accounts.containsKey('cash')) {
      await accounts.put(
        'cash',
        Account(id: 'cash', name: 'Cash', createdAt: DateTime.now()),
      );
    }
    if (!accounts.containsKey('bank')) {
      await accounts.put(
        'bank',
        Account(id: 'bank', name: 'Bank Account', createdAt: DateTime.now()),
      );
    }

    // Existing transactions from older versions are assigned to Cash.
    for (final tx in transactions.values) {
      if (tx.accountId.isEmpty) {
        tx.accountId = 'cash';
        await tx.save();
      }
    }
  }

  static Future<void> addAccount(Account account) async {
    await accounts.put(account.id, account);
  }

  static Future<void> deleteAccount(String id) async {
    await accounts.delete(id);
  }

  static List<Account> getAllAccounts() {
    return accounts.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static bool hasTransactionsForAccount(String id) =>
      transactions.values.any((tx) => tx.accountId == id);

  static bool hasLendingForAccount(String id) =>
      lending.values.any((entry) => entry.accountId == id);

  // ── Lending ──────────────────────────────────────────────────
  static Future<void> addLendingEntry(LendingEntry entry) async {
    await lending.put(entry.id, entry);
  }

  static Future<void> updateLendingEntry(LendingEntry entry) async {
    await lending.put(entry.id, entry);
  }

  static Future<void> deleteLendingEntry(String id) async {
    await lending.delete(id);
  }

  static List<LendingEntry> getAllLendingEntries() {
    return lending.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ── Transactions ──────────────────────────────────────────────
  static Future<void> addTransaction(Transaction tx) async {
    await transactions.put(tx.id, tx);
  }

  static Future<void> deleteTransaction(String id) async {
    await transactions.delete(id);
  }

  static Future<void> updateTransaction(Transaction tx) async {
    await transactions.put(tx.id, tx);
  }

  static List<Transaction> getAllTransactions() {
    return transactions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<Transaction> getTransactionsForMonth(int month, int year) {
    return transactions.values
        .where((t) => t.date.month == month && t.date.year == year)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<Transaction> getTransactionsForDateRange(
      DateTime start, DateTime end) {
    return transactions.values
        .where((t) =>
            t.date.isAfter(start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ── Monthly Reports ───────────────────────────────────────────
  static Future<void> saveReport(MonthlyReport report) async {
    await reports.put(report.id, report);
  }

  static List<MonthlyReport> getAllReports() {
    return reports.values.toList()
      ..sort((a, b) {
        final aDate = DateTime(a.year, a.month);
        final bDate = DateTime(b.year, b.month);
        return bDate.compareTo(aDate);
      });
  }

  static MonthlyReport? getReportForMonth(int month, int year) {
    try {
      return reports.values
          .firstWhere((r) => r.month == month && r.year == year);
    } catch (_) {
      return null;
    }
  }

  // ── Monthly Auto-Close ────────────────────────────────────────
  static Future<void> checkAndCloseMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastClosedMonth = prefs.getInt('lastClosedMonth') ?? 0;
    final lastClosedYear = prefs.getInt('lastClosedYear') ?? 0;

    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;

    if (lastClosedMonth == prevMonth && lastClosedYear == prevYear) return;

    final prevTxs = getTransactionsForMonth(prevMonth, prevYear);
    if (prevTxs.isEmpty) return;
    if (getReportForMonth(prevMonth, prevYear) != null) return;

    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> expenseBreakdown = {};
    Map<String, double> incomeBreakdown = {};

    for (final tx in prevTxs) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
        incomeBreakdown[tx.source] =
            (incomeBreakdown[tx.source] ?? 0) + tx.amount;
      } else {
        totalExpense += tx.amount;
        expenseBreakdown[tx.category] =
            (expenseBreakdown[tx.category] ?? 0) + tx.amount;
      }
    }

    final report = MonthlyReport(
      id: _uuid.v4(),
      month: prevMonth,
      year: prevYear,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      savings: totalIncome - totalExpense,
      generatedAt: now,
      expenseBreakdown: expenseBreakdown,
      incomeBreakdown: incomeBreakdown,
    );
    await saveReport(report);

    await prefs.setInt('lastClosedMonth', prevMonth);
    await prefs.setInt('lastClosedYear', prevYear);
  }

  // ── Delete All ─────────────────────────────────────────────────
  static Future<void> deleteAllData() async {
    await transactions.clear();
    await reports.clear();
    await accounts.clear();
    await lending.clear();
    await _ensureDefaultAccounts();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastClosedMonth');
    await prefs.remove('lastClosedYear');
  }

  // ── Backup / Restore ──────────────────────────────────────────
  static Map<String, dynamic> exportToJson() {
    final txList = transactions.values
        .map((t) => {
              'id': t.id,
              'amount': t.amount,
              'type': t.type.index,
              'category': t.category,
              'source': t.source,
              'note': t.note,
              'date': t.date.toIso8601String(),
              'time': t.time,
              'createdAt': t.createdAt.toIso8601String(),
              'accountId': t.accountId,
              'imagePath': t.imagePath,
            })
        .toList();

    final reportList = reports.values
        .map((r) => {
              'id': r.id,
              'month': r.month,
              'year': r.year,
              'totalIncome': r.totalIncome,
              'totalExpense': r.totalExpense,
              'savings': r.savings,
              'generatedAt': r.generatedAt.toIso8601String(),
              'expenseBreakdown': r.expenseBreakdown,
              'incomeBreakdown': r.incomeBreakdown,
            })
        .toList();

    final accountList = accounts.values
        .map((a) => {
              'id': a.id,
              'name': a.name,
              'initialBalance': a.initialBalance,
              'createdAt': a.createdAt.toIso8601String(),
            })
        .toList();

    final lendingList = lending.values
        .map((e) => {
              'id': e.id,
              'person': e.person,
              'amount': e.amount,
              'repaidAmount': e.repaidAmount,
              'direction': e.direction.index,
              'dueDate': e.dueDate?.toIso8601String(),
              'note': e.note,
              'createdAt': e.createdAt.toIso8601String(),
              'accountId': e.accountId,
            })
        .toList();

    return {
      'transactions': txList,
      'reports': reportList,
      'accounts': accountList,
      'lending': lendingList,
      'version': 2,
    };
  }

  static Future<void> importFromJson(Map<String, dynamic> data) async {
    await transactions.clear();
    await reports.clear();
    await accounts.clear();
    await lending.clear();

    final txList = (data['transactions'] as List?) ?? const [];
    for (final t in txList) {
      final tx = Transaction(
        id: t['id'],
        amount: (t['amount'] as num).toDouble(),
        type: TransactionType.values[t['type']],
        category: t['category'],
        source: t['source'],
        note: t['note'] ?? '',
        date: DateTime.parse(t['date']),
        time: t['time'],
        createdAt: DateTime.parse(t['createdAt']),
        accountId: t['accountId'] ?? 'cash',
        imagePath: t['imagePath'],
      );
      await transactions.put(tx.id, tx);
    }

    final reportList = (data['reports'] as List?) ?? const [];
    for (final r in reportList) {
      final report = MonthlyReport(
        id: r['id'],
        month: r['month'],
        year: r['year'],
        totalIncome: (r['totalIncome'] as num).toDouble(),
        totalExpense: (r['totalExpense'] as num).toDouble(),
        savings: (r['savings'] as num).toDouble(),
        generatedAt: DateTime.parse(r['generatedAt']),
        expenseBreakdown: Map<String, double>.from(r['expenseBreakdown'] ?? {}),
        incomeBreakdown: Map<String, double>.from(r['incomeBreakdown'] ?? {}),
      );
      await reports.put(report.id, report);
    }

    final accountList = (data['accounts'] as List?) ?? const [];
    for (final a in accountList) {
      final account = Account(
        id: a['id'],
        name: a['name'],
        initialBalance: (a['initialBalance'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(a['createdAt']),
      );
      await accounts.put(account.id, account);
    }

    final lendingList = (data['lending'] as List?) ?? const [];
    for (final e in lendingList) {
      final entry = LendingEntry(
        id: e['id'],
        person: e['person'],
        amount: (e['amount'] as num).toDouble(),
        repaidAmount: (e['repaidAmount'] as num?)?.toDouble() ?? 0,
        direction: LendingDirection.values[e['direction'] as int],
        dueDate: e['dueDate'] == null ? null : DateTime.parse(e['dueDate']),
        note: e['note'] ?? '',
        createdAt: DateTime.parse(e['createdAt']),
        accountId: e['accountId'] ?? 'cash',
      );
      await lending.put(entry.id, entry);
    }

    await _ensureDefaultAccounts();
  }
}
