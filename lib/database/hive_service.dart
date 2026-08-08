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
    await _migrateLegacyAccountIds();
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

    // Never leave transactions or lending entries pointing at a missing
    // account. Legacy versions used both an empty account id and "default".
    for (final tx in transactions.values) {
      final normalized = _normalizeAccountId(tx.accountId);
      if (normalized != tx.accountId || !accounts.containsKey(normalized)) {
        tx.accountId = accounts.containsKey(normalized) ? normalized : 'cash';
        await tx.save();
      }
    }
    for (final entry in lending.values) {
      final normalized = _normalizeAccountId(entry.accountId);
      if (normalized != entry.accountId || !accounts.containsKey(normalized)) {
        entry.accountId = accounts.containsKey(normalized) ? normalized : 'cash';
        await entry.save();
      }
    }
  }

  static String _normalizeAccountId(dynamic rawId) {
    final id = rawId?.toString().trim() ?? '';
    if (id.isEmpty || id == 'default' || id == 'primary') return 'cash';
    return id;
  }

  static Future<void> _migrateLegacyAccountIds() async {
    // Intermediate builds used "default" as the primary account id. Remove
    // that legacy account after its balance has been carried into Cash.
    final legacyIds = ['default', 'primary'];
    for (final legacyId in legacyIds) {
      final legacy = accounts.get(legacyId);
      if (legacy == null) continue;
      final cash = accounts.get('cash');
      if (cash != null && legacy.initialBalance != 0) {
        cash.initialBalance += legacy.initialBalance;
        await cash.save();
      }
      await accounts.delete(legacyId);
    }

    await _ensureDefaultAccounts();
  }

  static Future<void> addAccount(Account account) async {
    await accounts.put(account.id, account);
  }

  static Future<void> updateAccount(Account account) async {
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

  static List<Transaction> getTransactionsForAccount(String id) {
    return transactions.values
        .where((tx) => tx.accountId == id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

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
    if (data.isEmpty) throw const FormatException('Backup is empty.');

    final rawTransactions = data['transactions'];
    final rawReports = data['reports'];
    final rawAccounts = data['accounts'];
    final rawLending = data['lending'];

    if (rawTransactions != null && rawTransactions is! List) {
      throw const FormatException('Invalid transactions section.');
    }
    if (rawReports != null && rawReports is! List) {
      throw const FormatException('Invalid reports section.');
    }
    if (rawAccounts != null && rawAccounts is! List) {
      throw const FormatException('Invalid accounts section.');
    }
    if (rawLending != null && rawLending is! List) {
      throw const FormatException('Invalid lending section.');
    }

    // Clear only after the backup has passed basic validation.
    await transactions.clear();
    await reports.clear();
    await accounts.clear();
    await lending.clear();

    final accountIdMap = <String, String>{};
    final accountList = (rawAccounts as List?) ?? const [];

    for (final raw in accountList) {
      if (raw is! Map) continue;
      final oldId = raw['id']?.toString().trim() ?? '';
      if (oldId.isEmpty) continue;

      final normalizedId = _normalizeAccountId(oldId);
      accountIdMap[oldId] = normalizedId;

      final rawCreatedAt = raw['createdAt'];
      final createdAt = rawCreatedAt == null
          ? DateTime.now()
          : DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now();
      final rawBalance = raw['initialBalance'];
      final initialBalance = rawBalance is num ? rawBalance.toDouble() : 0.0;

      var name = raw['name']?.toString().trim() ?? '';
      if (normalizedId == 'cash') name = 'Cash';
      if (normalizedId == 'bank') name = 'Bank Account';
      if (name.isEmpty) name = normalizedId == 'cash' ? 'Cash' : 'Account';

      // If an old backup contains both "default" and "cash", let the
      // canonical cash record win instead of overwriting it unpredictably.
      if (accounts.containsKey(normalizedId)) continue;

      await accounts.put(
        normalizedId,
        Account(
          id: normalizedId,
          name: name,
          initialBalance: initialBalance,
          createdAt: createdAt,
        ),
      );
    }

    final txList = (rawTransactions as List?) ?? const [];
    for (final raw in txList) {
      if (raw is! Map) continue;
      final id = raw['id']?.toString();
      final amount = raw['amount'];
      if (id == null || amount is! num) continue;

      final typeIndex = raw['type'] is num ? (raw['type'] as num).toInt() : 1;
      final type = typeIndex >= 0 && typeIndex < TransactionType.values.length
          ? TransactionType.values[typeIndex]
          : TransactionType.expense;
      final date = DateTime.tryParse(raw['date']?.toString() ?? '');
      final createdAt = DateTime.tryParse(raw['createdAt']?.toString() ?? '');
      if (date == null || createdAt == null) continue;

      final rawAccountId = raw['accountId']?.toString() ?? '';
      final accountId = accountIdMap[rawAccountId] ?? _normalizeAccountId(rawAccountId);
      final safeAccountId = accounts.containsKey(accountId) ? accountId : 'cash';

      final tx = Transaction(
        id: id,
        amount: amount.toDouble(),
        type: type,
        category: raw['category']?.toString() ?? '',
        source: raw['source']?.toString() ?? '',
        note: raw['note']?.toString() ?? '',
        date: date,
        time: raw['time']?.toString() ?? '00:00',
        createdAt: createdAt,
        accountId: safeAccountId,
        imagePath: raw['imagePath']?.toString(),
      );
      await transactions.put(tx.id, tx);
    }

    final reportList = (rawReports as List?) ?? const [];
    for (final raw in reportList) {
      if (raw is! Map) continue;
      final id = raw['id']?.toString();
      if (id == null) continue;
      final generatedAt = DateTime.tryParse(raw['generatedAt']?.toString() ?? '') ?? DateTime.now();
      final expense = _doubleMap(raw['expenseBreakdown']);
      final income = _doubleMap(raw['incomeBreakdown']);
      final totalIncome = raw['totalIncome'] is num ? (raw['totalIncome'] as num).toDouble() : 0.0;
      final totalExpense = raw['totalExpense'] is num ? (raw['totalExpense'] as num).toDouble() : 0.0;
      final savings = raw['savings'] is num ? (raw['savings'] as num).toDouble() : totalIncome - totalExpense;

      final report = MonthlyReport(
        id: id,
        month: raw['month'] is num ? (raw['month'] as num).toInt() : generatedAt.month,
        year: raw['year'] is num ? (raw['year'] as num).toInt() : generatedAt.year,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        savings: savings,
        generatedAt: generatedAt,
        expenseBreakdown: expense,
        incomeBreakdown: income,
      );
      await reports.put(report.id, report);
    }

    final lendingList = (rawLending as List?) ?? const [];
    for (final raw in lendingList) {
      if (raw is! Map) continue;
      final id = raw['id']?.toString();
      final amount = raw['amount'];
      if (id == null || amount is! num) continue;

      final directionIndex = raw['direction'] is num ? (raw['direction'] as num).toInt() : 0;
      final direction = directionIndex >= 0 && directionIndex < LendingDirection.values.length
          ? LendingDirection.values[directionIndex]
          : LendingDirection.lent;
      final createdAt = DateTime.tryParse(raw['createdAt']?.toString() ?? '') ?? DateTime.now();
      final dueDate = raw['dueDate'] == null ? null : DateTime.tryParse(raw['dueDate'].toString());
      final rawAccountId = raw['accountId']?.toString() ?? '';
      final accountId = accountIdMap[rawAccountId] ?? _normalizeAccountId(rawAccountId);
      final safeAccountId = accounts.containsKey(accountId) ? accountId : 'cash';
      final repaid = raw['repaidAmount'] is num ? (raw['repaidAmount'] as num).toDouble() : 0.0;

      final entry = LendingEntry(
        id: id,
        person: raw['person']?.toString() ?? '',
        amount: amount.toDouble(),
        repaidAmount: repaid.clamp(0, amount.toDouble()).toDouble(),
        direction: direction,
        dueDate: dueDate,
        note: raw['note']?.toString() ?? '',
        createdAt: createdAt,
        accountId: safeAccountId,
      );
      await lending.put(entry.id, entry);
    }

    await _ensureDefaultAccounts();
  }

  static Map<String, double> _doubleMap(dynamic value) {
    if (value is! Map) return <String, double>{};
    return value.map<String, double>((key, val) {
      final number = val is num ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0;
      return MapEntry(key.toString(), number);
    });
  }

}
