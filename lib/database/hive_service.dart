import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/monthly_report.dart';

class HiveService {
  static const String _transactionsBox = 'transactions';
  static const String _reportsBox = 'monthly_reports';
  static const _uuid = Uuid();

  static Box<Transaction> get transactions =>
      Hive.box<Transaction>(_transactionsBox);

  static Box<MonthlyReport> get reports =>
      Hive.box<MonthlyReport>(_reportsBox);

  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(MonthlyReportAdapter());
    await Hive.openBox<Transaction>(_transactionsBox);
    await Hive.openBox<MonthlyReport>(_reportsBox);
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

    // Already closed this previous month
    if (lastClosedMonth == prevMonth && lastClosedYear == prevYear) return;

    // Check if there are any transactions for the previous month
    final prevTxs = getTransactionsForMonth(prevMonth, prevYear);
    if (prevTxs.isEmpty) return;

    // Don't close if report already exists
    if (getReportForMonth(prevMonth, prevYear) != null) return;

    // Calculate totals
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

    final savings = totalIncome - totalExpense;

    // Save the monthly report
    final report = MonthlyReport(
      id: _uuid.v4(),
      month: prevMonth,
      year: prevYear,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      savings: savings,
      generatedAt: now,
      expenseBreakdown: expenseBreakdown,
      incomeBreakdown: incomeBreakdown,
    );
    await saveReport(report);

    // Carry forward savings as income for this month
    if (savings > 0) {
      final carryForward = Transaction(
        id: _uuid.v4(),
        amount: savings,
        type: TransactionType.income,
        category: 'Savings',
        source: 'Previous Month Savings',
        note: 'Auto carry-forward from ${_monthName(prevMonth)} $prevYear',
        date: DateTime(now.year, now.month, 1),
        time: '00:00',
        createdAt: now,
      );
      await addTransaction(carryForward);
    }

    // Update last closed month
    await prefs.setInt('lastClosedMonth', prevMonth);
    await prefs.setInt('lastClosedYear', prevYear);
  }

  static String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }

  // ── Delete All ─────────────────────────────────────────────────
  static Future<void> deleteAllData() async {
    await transactions.clear();
    await reports.clear();
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

    return {'transactions': txList, 'reports': reportList, 'version': 1};
  }

  static Future<void> importFromJson(Map<String, dynamic> data) async {
    await transactions.clear();
    await reports.clear();

    final txList = data['transactions'] as List;
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
      );
      await transactions.put(tx.id, tx);
    }

    final reportList = data['reports'] as List;
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
  }
}
