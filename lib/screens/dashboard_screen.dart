import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction.dart';
import '../themes/app_theme.dart';
import '../utils/app_utils.dart';
import '../widgets/balance_card.dart';
import '../widgets/savings_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/add_transaction_sheet.dart';

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
      duration: const Duration(milliseconds: 300), vsync: this,
    );
  }

  @override
  void dispose() { _fabController.dispose(); super.dispose(); }

  void _toggleFab() {
    HapticFeedback.lightImpact();
    setState(() => _fabExpanded = !_fabExpanded);
    _fabExpanded ? _fabController.forward() : _fabController.reverse();
  }

  void _showAddTransaction(TransactionType type) {
    _toggleFab();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(initialType: type),
    );
  }

  void _showAccountSwitcher(BuildContext context, AccountProvider accProvider, bool isDark) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Switch Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1C1C1E))),
            GestureDetector(
              onTap: () { Navigator.pop(ctx); _showAddAccountSheet(context, accProvider, isDark); },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: AppColors.accentBlue, size: 16),
                  SizedBox(width: 4),
                  Text('Add', style: TextStyle(color: AppColors.accentBlue, fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          ...accProvider.accounts.map((acc) {
            final isActive = acc.id == accProvider.activeAccountId;
            final color = Color(acc.colorValue);
            return GestureDetector(
              onTap: () {
                accProvider.setActiveAccount(acc.id);
                context.read<TransactionProvider>().setActiveAccount(acc.id);
                Navigator.pop(ctx);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isActive ? color.withOpacity(0.1) : (isDark ? AppColors.darkCard : const Color(0xFFF2F2F7)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isActive ? color : Colors.transparent, width: 1.5),
                ),
                child: Row(children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(IconData(acc.iconCodePoint, fontFamily: 'MaterialIcons'), color: color, size: 20)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(acc.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1C1C1E))),
                    Text(acc.accountType, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : Colors.grey[500])),
                  ])),
                  if (isActive) Icon(Icons.check_circle_rounded, color: color, size: 22),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context, AccountProvider accProvider, bool isDark) {
    final nameCtrl = TextEditingController();
    int colorIdx = 0; int iconIdx = 0; int typeIdx = 0;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return Container(
          decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            Text('New Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1C1C1E))),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1C1C1E)), decoration: const InputDecoration(hintText: 'Account name...')),
            const SizedBox(height: 16),
            Text('TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: isDark ? AppColors.textSecondary : Colors.grey[500])),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: AccountProvider.accountTypes.asMap().entries.map((e) {
              final sel = e.key == typeIdx;
              return GestureDetector(onTap: () => setS(() => typeIdx = e.key),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: sel ? AppColors.accentBlue : (isDark ? AppColors.darkCard : const Color(0xFFF2F2F7)), borderRadius: BorderRadius.circular(12)),
                  child: Text(e.value['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600])))));
            }).toList()),
            const SizedBox(height: 16),
            Text('COLOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: isDark ? AppColors.textSecondary : Colors.grey[500])),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: AccountProvider.accountColors.asMap().entries.map((e) {
              final sel = e.key == colorIdx;
              return GestureDetector(onTap: () => setS(() => colorIdx = e.key),
                child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: sel ? 34 : 28, height: sel ? 34 : 28,
                  decoration: BoxDecoration(color: e.value, shape: BoxShape.circle, border: Border.all(color: sel ? Colors.white : Colors.transparent, width: sel ? 3 : 0))));
            }).toList()),
            const SizedBox(height: 16),
            Text('ICON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: isDark ? AppColors.textSecondary : Colors.grey[500])),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: AccountProvider.accountIcons.asMap().entries.map((e) {
              final sel = e.key == iconIdx; final c = AccountProvider.accountColors[colorIdx];
              return GestureDetector(onTap: () => setS(() => iconIdx = e.key),
                child: Container(width: 34, height: 34,
                  decoration: BoxDecoration(color: sel ? c.withOpacity(0.15) : (isDark ? AppColors.darkCard : const Color(0xFFF2F2F7)), borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? c : Colors.transparent, width: 1.5)),
                  child: Icon(e.value['icon'] as IconData, size: 16, color: sel ? c : (isDark ? Colors.white38 : Colors.grey[500]))));
            }).toList()),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final c = AccountProvider.accountColors[colorIdx];
                final ic = AccountProvider.accountIcons[iconIdx]['icon'] as IconData;
                final tp = AccountProvider.accountTypes[typeIdx]['label'] as String;
                await accProvider.addAccount(name: nameCtrl.text.trim(), colorValue: c.value, iconCodePoint: ic.codePoint, accountType: tp);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AccountProvider.accountColors[colorIdx], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            )),
          ])),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final accProvider = context.watch<AccountProvider>();
    final isDark = themeProvider.isDarkMode;
    final currency = themeProvider.currency;
    final now = DateTime.now();
    final activeAcc = accProvider.activeAccount;
    final accColor = activeAcc != null ? Color(activeAcc.colorValue) : AppColors.accentBlue;
    final accName = activeAcc?.name ?? 'Account';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(child: Stack(children: [
        RefreshIndicator(
          onRefresh: () async { txProvider.loadTransactions(); },
          color: AppColors.accentBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header with account switcher ─────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Good ${_greeting()},', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondary : Colors.grey[600], fontWeight: FontWeight.w500)),
                    Text(AppDateUtils.fullMonthName(now.month), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1C1C1E))),
                  ]),
                  // Account chip
                  GestureDetector(
                    onTap: () => _showAccountSwitcher(context, accProvider, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: accColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: accColor.withOpacity(0.25))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (activeAcc != null) Icon(IconData(activeAcc.iconCodePoint, fontFamily: 'MaterialIcons'), color: accColor, size: 16),
                        const SizedBox(width: 6),
                        Text(accName, style: TextStyle(color: accColor, fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, color: accColor, size: 18),
                      ]),
                    ),
                  ),
                ]).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
              )),

              // ── Balance Card ──────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: BalanceCard(
                  balance: txProvider.currentMonthBalance,
                  income: txProvider.currentMonthIncome,
                  expense: txProvider.currentMonthExpense,
                  currency: currency, isDark: isDark,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1)),

              // ── Savings Card ──────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SavingsCard(
                  combinedSavings: txProvider.combinedNetSavings,
                  accountSavings: txProvider.accountNetSavings,
                  accountName: accName,
                  accountColor: accColor,
                  currency: currency, isDark: isDark,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(begin: 0.1)),

              // ── Summary Row ───────────────────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  _SummaryChip(label: 'Income', amount: txProvider.currentMonthIncome, color: AppColors.incomeGreen, icon: Icons.arrow_downward_rounded, currency: currency, isDark: isDark),
                  const SizedBox(width: 10),
                  _SummaryChip(label: 'Expense', amount: txProvider.currentMonthExpense, color: AppColors.expenseRed, icon: Icons.arrow_upward_rounded, currency: currency, isDark: isDark),
                  const SizedBox(width: 10),
                  _SummaryChip(label: 'Saved', amount: txProvider.currentMonthBalance.clamp(0, double.infinity), color: AppColors.savingsBlue, icon: Icons.savings_outlined, currency: currency, isDark: isDark),
                ]).animate().fadeIn(duration: 500.ms, delay: 200.ms),
              )),

              // ── Recent Transactions Header ────────────
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1C1C1E))),
                  TextButton(onPressed: widget.onSeeAll, child: Text('See all', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w600, fontSize: 14))),
                ]).animate().fadeIn(duration: 500.ms, delay: 300.ms),
              )),

              // ── Transactions List ─────────────────────
              txProvider.recentTransactions.isEmpty
                  ? SliverToBoxAdapter(child: _EmptyState(isDark: isDark).animate().fadeIn(duration: 500.ms, delay: 400.ms))
                  : SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                      final tx = txProvider.recentTransactions[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: TransactionTile(transaction: tx, currency: currency, isDark: isDark,
                          onDelete: () => txProvider.deleteTransaction(tx.id),
                        ).animate().fadeIn(duration: 400.ms, delay: (300 + index * 60).ms).slideX(begin: 0.05),
                      );
                    }, childCount: txProvider.recentTransactions.length)),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
        // ── FAB ─────────────────────────────────────
        Positioned(bottom: 24, right: 24, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (_fabExpanded) ...[
            _MiniFAB(label: 'Add Income', icon: Icons.add, color: AppColors.incomeGreen, onTap: () => _showAddTransaction(TransactionType.income)).animate().fadeIn(duration: 200.ms).slideY(begin: 0.5),
            const SizedBox(height: 10),
            _MiniFAB(label: 'Add Expense', icon: Icons.remove, color: AppColors.expenseRed, onTap: () => _showAddTransaction(TransactionType.expense)).animate().fadeIn(duration: 200.ms, delay: 50.ms).slideY(begin: 0.5),
            const SizedBox(height: 10),
          ],
          GestureDetector(onTap: _toggleFab, child: AnimatedContainer(
            duration: const Duration(milliseconds: 300), width: 58, height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _fabExpanded ? [Colors.grey.shade700, Colors.grey.shade600] : [AppColors.accentBlue, const Color(0xFF0060CF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: (_fabExpanded ? Colors.grey : AppColors.accentBlue).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: AnimatedRotation(duration: const Duration(milliseconds: 300), turns: _fabExpanded ? 0.125 : 0, child: const Icon(Icons.add, color: Colors.white, size: 28)),
          )),
        ])),
      ])),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _SummaryChip extends StatelessWidget {
  final String label; final double amount; final Color color; final IconData icon; final String currency; final bool isDark;
  const _SummaryChip({required this.label, required this.amount, required this.color, required this.icon, required this.currency, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondary : Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(CurrencyFormatter.formatCompact(amount, currency), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1C1C1E)), overflow: TextOverflow.ellipsis),
      ]),
    ));
  }
}

class _MiniFAB extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _MiniFAB({required this.label, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
      const SizedBox(width: 10),
      Container(width: 46, height: 46, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Icon(icon, color: Colors.white, size: 22)),
    ]));
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(40), child: Column(children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.receipt_long_outlined, color: AppColors.accentBlue, size: 36)),
      const SizedBox(height: 16),
      Text('No transactions yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1C1C1E))),
      const SizedBox(height: 8),
      Text('Tap the + button to add your first transaction', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondary : Colors.grey[600])),
    ]));
  }
}
