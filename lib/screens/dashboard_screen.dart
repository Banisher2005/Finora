import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/theme_provider.dart';
import '../models/transaction.dart';
import '../themes/app_theme.dart';
import '../utils/app_utils.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/add_transaction_sheet.dart';
import 'accounts_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onSeeAll;
  const DashboardScreen({super.key, this.onSeeAll});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _fabExpanded = false;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    HapticFeedback.lightImpact();
    setState(() => _fabExpanded = !_fabExpanded);
    if (_fabExpanded) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  void _showAddTransaction(TransactionType type) {
    _toggleFab();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(initialType: type),
    );
  }

  void _editTransaction(Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        initialType: tx.type,
        transaction: tx,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final currency = themeProvider.currency;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                txProvider.loadTransactions();
              },
              color: AppColors.accentBlue,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header ──────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good ${_greeting()},',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                AppDateUtils.fullMonthName(now.month),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF172033),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppDateUtils.formatDateShort(now),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.grey[700],
                                ),
                              ),
                              Text(
                                '${now.year}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondary : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                    ),
                  ),

                  // ── Balance Card ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: BalanceCard(
                        balance: accountProvider.totalBalance(txProvider.transactions),
                        income: txProvider.currentMonthIncome,
                        expense: txProvider.currentMonthExpense,
                        currency: currency,
                        isDark: isDark,
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1),
                  ),

                  // ── Account balances ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _AccountBalanceStrip(
                        cashBalance: accountProvider.balanceFor(
                          'cash',
                          txProvider.transactions,
                        ),
                        bankBalance: accountProvider.balanceFor(
                          'bank',
                          txProvider.transactions,
                        ),
                        currency: currency,
                        isDark: isDark,
                        onCashTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountsScreen(initialFocusAccountId: 'cash'),
                          ),
                        ),
                        onBankTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountsScreen(initialFocusAccountId: 'bank'),
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
                    ),
                  ),

                  // ── Recent Transactions Header ───────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF172033),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onSeeAll,
                            child: Text(
                              'See all',
                              style: TextStyle(
                                color: AppColors.accentBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                    ),
                  ),

                  // ── Transactions List ────────────────────────
                  txProvider.recentTransactions.isEmpty
                      ? SliverToBoxAdapter(
                          child: _EmptyState(isDark: isDark)
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 400.ms),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final tx =
                                  txProvider.recentTransactions[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 8),
                                child: TransactionTile(
                                  transaction: tx,
                                  currency: currency,
                                  isDark: isDark,
                                  onDelete: () =>
                                      txProvider.deleteTransaction(tx.id),
                                  onEdit: () => _editTransaction(tx),
                                ).animate()
                                    .fadeIn(duration: 400.ms, delay: (300 + index * 60).ms)
                                    .slideX(begin: 0.05),
                              );
                            },
                            childCount: txProvider.recentTransactions.length,
                          ),
                        ),

                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),

            // ── FAB ─────────────────────────────────────────────
            Positioned(
              bottom: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_fabExpanded) ...[
                    _MiniFAB(
                      label: 'Add Income',
                      icon: Icons.add,
                      color: AppColors.incomeGreen,
                      onTap: () => _showAddTransaction(TransactionType.income),
                    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.5),
                    const SizedBox(height: 10),
                    _MiniFAB(
                      label: 'Add Expense',
                      icon: Icons.remove,
                      color: AppColors.expenseRed,
                      onTap: () => _showAddTransaction(TransactionType.expense),
                    ).animate().fadeIn(duration: 200.ms, delay: 50.ms).slideY(begin: 0.5),
                    const SizedBox(height: 10),
                  ],
                  GestureDetector(
                    onTap: _toggleFab,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _fabExpanded
                              ? [Colors.grey.shade700, Colors.grey.shade600]
                              : [AppColors.accentBlue, const Color(0xFF0060CF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: (_fabExpanded
                                    ? Colors.grey
                                    : AppColors.accentBlue)
                                .withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: _fabExpanded ? 0.125 : 0,
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _AccountBalanceStrip extends StatelessWidget {
  final double cashBalance;
  final double bankBalance;
  final String currency;
  final bool isDark;
  final VoidCallback onCashTap;
  final VoidCallback onBankTap;

  const _AccountBalanceStrip({
    required this.cashBalance,
    required this.bankBalance,
    required this.currency,
    required this.isDark,
    required this.onCashTap,
    required this.onBankTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AccountBalanceCard(
            label: 'Cash Balance',
            amount: cashBalance,
            currency: currency,
            icon: Icons.payments_rounded,
            accent: AppColors.accentTeal,
            isDark: isDark,
            onTap: onCashTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AccountBalanceCard(
            label: 'Bank Balance',
            amount: bankBalance,
            currency: currency,
            icon: Icons.account_balance_rounded,
            accent: AppColors.savingsBlue,
            isDark: isDark,
            onTap: onBankTap,
          ),
        ),
      ],
    );
  }
}


class _AccountBalanceCard extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _AccountBalanceCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withOpacity(isDark ? 0.18 : 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.12 : 0.045),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: accent, size: 18),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondary : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  CurrencyFormatter.format(amount, currency),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : const Color(0xFF172033),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _MiniFAB extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniFAB({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.accentBlue,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first transaction',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondary : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
