import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart';
import '../themes/app_theme.dart';
import '../utils/app_utils.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/add_transaction_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  TransactionType? _filterType;
  String _search = '';

  // ── Month navigation ───────────────────────────────────────────
  DateTime _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _viewMonth.month == now.month && _viewMonth.year == now.year;
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_viewMonth.year, _viewMonth.month + 1);
    if (next.year > now.year ||
        (next.year == now.year && next.month > now.month)) return;
    setState(() => _viewMonth = next);
  }

  List<Transaction> _getViewMonthTransactions(List<Transaction> all) {
    var list = all.where((t) =>
        t.date.month == _viewMonth.month &&
        t.date.year == _viewMonth.year).toList();

    if (_filterType != null) {
      list = list.where((t) => t.type == _filterType).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((t) =>
          t.note.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          t.source.toLowerCase().contains(q) ||
          t.amount.toString().contains(q)).toList();
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Map<String, List<Transaction>> _group(List<Transaction> txns) {
    final Map<String, List<Transaction>> grouped = {};
    for (final t in txns) {
      final key = AppDateUtils.formatDate(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addTransaction(TransactionType type) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        initialType: type,
        initialDate: _isCurrentMonth ? null : _viewMonth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final currency = themeProvider.currency;

    final viewTxns = _getViewMonthTransactions(txProvider.transactions);
    final grouped = _group(viewTxns);
    final keys = grouped.keys.toList();

    // Month totals
    double income = viewTxns
        .where((t) => t.type == TransactionType.income)
        .fold(0, (s, t) => s + t.amount);
    double expense = viewTxns
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Month navigator ──────────────────────────
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _prevMonth,
                          icon: Icon(Icons.chevron_left_rounded,
                              color: isDark ? Colors.white70 : Colors.grey[700]),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              AppDateUtils.formatMonthYear(
                                  _viewMonth.month, _viewMonth.year),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _isCurrentMonth ? null : _nextMonth,
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color: _isCurrentMonth
                                ? Colors.grey[400]
                                : (isDark ? Colors.white70 : Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Month totals row ─────────────────────────
                  Row(
                    children: [
                      _MiniStat(
                        label: 'Income',
                        amount: income,
                        currency: currency,
                        color: AppColors.incomeGreen,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _MiniStat(
                        label: 'Expense',
                        amount: expense,
                        currency: currency,
                        color: AppColors.expenseRed,
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Search ────────────────────────────────────
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search transactions…',
                      prefixIcon: Icon(Icons.search_rounded,
                          color: isDark ? Colors.white38 : Colors.grey[400],
                          size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Filter chips ──────────────────────────────
                  Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _filterType == null,
                        isDark: isDark,
                        onTap: () => setState(() => _filterType = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Income',
                        isSelected: _filterType == TransactionType.income,
                        isDark: isDark,
                        color: AppColors.incomeGreen,
                        onTap: () => setState(() => _filterType =
                            _filterType == TransactionType.income
                                ? null
                                : TransactionType.income),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Expense',
                        isSelected: _filterType == TransactionType.expense,
                        isDark: isDark,
                        color: AppColors.expenseRed,
                        onTap: () => setState(() => _filterType =
                            _filterType == TransactionType.expense
                                ? null
                                : TransactionType.expense),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),

            const SizedBox(height: 8),

            // ── Transaction List ─────────────────────────────
            Expanded(
              child: viewTxns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 56,
                              color: isDark ? Colors.white24 : Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions',
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondary : Colors.grey[500],
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to add one',
                            style: TextStyle(
                              color: isDark ? Colors.white24 : Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      itemCount: keys.length,
                      itemBuilder: (ctx, i) {
                        final dayKey = keys[i];
                        final dayTxns = grouped[dayKey]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                dayKey,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : Colors.grey[500],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...dayTxns.map((t) => TransactionTile(
                                  transaction: t,
                                  currency: currency,
                                  isDark: isDark,
                                  onDelete: () => context
                                      .read<TransactionProvider>()
                                      .deleteTransaction(t.id),
                                ).animate().fadeIn(
                                    duration: 250.ms,
                                    delay: Duration(
                                        milliseconds: dayTxns.indexOf(t) * 40))),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // ── FAB ──────────────────────────────────────────────
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'tx_income',
            onPressed: () => _addTransaction(TransactionType.income),
            backgroundColor: AppColors.incomeGreen,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'tx_expense',
            onPressed: () => _addTransaction(TransactionType.expense),
            backgroundColor: AppColors.expenseRed,
            child: const Icon(Icons.remove, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  final bool isDark;

  const _MiniStat({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondary : Colors.grey[500],
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            FittedBox(
              child: Text(
                CurrencyFormatter.format(amount, currency),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ),
            if (amount >= 1000)
              Text(
                CurrencyFormatter.wordLabel(amount, currency),
                style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.6),
                    fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accentBlue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? c.withOpacity(0.15)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? c : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? c
                : (isDark ? Colors.white54 : Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}
