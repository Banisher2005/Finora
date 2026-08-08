
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/account_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../themes/app_theme.dart';
import '../utils/app_utils.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/transaction_tile.dart';

enum _AccountGroup { all, cash, bank, custom }

class AccountsScreen extends StatefulWidget {
  final String? initialFocusAccountId;

  const AccountsScreen({super.key, this.initialFocusAccountId});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late _AccountGroup _group;

  @override
  void initState() {
    super.initState();
    _group = _groupFromId(widget.initialFocusAccountId);
  }

  _AccountGroup _groupFromId(String? accountId) {
    switch (accountId) {
      case 'cash':
        return _AccountGroup.cash;
      case 'bank':
        return _AccountGroup.bank;
      default:
        return _AccountGroup.all;
    }
  }

  Future<void> _openAddAccountDialog() async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');

    final result = await showDialog<(String, double)?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: const Text('Add account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Account name',
                hintText: 'e.g. Wallet, Savings, UPI',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Opening balance',
                hintText: '0',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final balance = double.tryParse(
                    balanceController.text.replaceAll(',', '').trim(),
                  ) ??
                  0;
              if (name.isNotEmpty) Navigator.pop(ctx, (name, balance));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    nameController.dispose();
    balanceController.dispose();

    if (result == null || !mounted) return;
    await context.read<AccountProvider>().addAccount(
          result.$1,
          initialBalance: result.$2,
        );
  }

  Future<void> _editAccountDialog(Account account) async {
    final nameController = TextEditingController(text: account.name);
    final balanceController =
        TextEditingController(text: account.initialBalance.toStringAsFixed(2));

    final result = await showDialog<(String, double)?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text('Edit ${account.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Account name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Opening balance',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final balance = double.tryParse(
                    balanceController.text.replaceAll(',', '').trim(),
                  ) ??
                  0;
              if (name.isNotEmpty) Navigator.pop(ctx, (name, balance));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    balanceController.dispose();

    if (result == null || !mounted) return;
    account.name = result.$1;
    account.initialBalance = result.$2;
    await context.read<AccountProvider>().updateAccount(account);
  }

  Future<void> _deleteAccount(Account account) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${account.name}?'),
        content: const Text(
          'This account can only be deleted when it has no transactions or lending entries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expenseRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final deleted = await context.read<AccountProvider>().deleteAccount(account.id);
    if (!deleted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This account is in use and cannot be deleted.'),
        ),
      );
    }
  }

  void _addTransactionForAccount(Account account, TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(
        initialType: type,
        initialAccountId: account.id,
      ),
    );
  }

  void _openAccountDetails(Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountDetailsSheet(
        account: account,
        onEdit: () => _editAccountDialog(account),
        onDelete: () => _deleteAccount(account),
        onAddIncome: () => _addTransactionForAccount(account, TransactionType.income),
        onAddExpense: () => _addTransactionForAccount(account, TransactionType.expense),
      ),
    );
  }

  List<Account> _visibleAccounts(AccountProvider provider) {
    switch (_group) {
      case _AccountGroup.cash:
        return provider.accounts.where((a) => a.id == 'cash').toList();
      case _AccountGroup.bank:
        return provider.accounts.where((a) => a.id == 'bank').toList();
      case _AccountGroup.custom:
        return provider.customAccounts;
      case _AccountGroup.all:
        return provider.accounts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final currency = themeProvider.currency;

    final accounts = _visibleAccounts(accountProvider);
    final totalBalance = accountProvider.totalBalance(txProvider.transactions);
    final cashBalance = accountProvider.balanceFor('cash', txProvider.transactions);
    final bankBalance = accountProvider.balanceFor('bank', txProvider.transactions);
    final customBalance = totalBalance - cashBalance - bankBalance;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddAccountDialog,
        backgroundColor: AppColors.accentBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Account'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : const Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Accounts',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF172033),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.gradientDarkStart, AppColors.gradientDarkEnd]
                        : [AppColors.gradientLightStart, AppColors.gradientLightEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.format(totalBalance, currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryMiniCard(
                            label: 'Cash',
                            amount: cashBalance,
                            currency: currency,
                            icon: Icons.payments_rounded,
                            accent: AppColors.accentTeal,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryMiniCard(
                            label: 'Bank',
                            amount: bankBalance,
                            currency: currency,
                            icon: Icons.account_balance_rounded,
                            accent: AppColors.savingsBlue,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryMiniCard(
                            label: 'Custom',
                            amount: customBalance,
                            currency: currency,
                            icon: Icons.folder_copy_rounded,
                            accent: AppColors.accentPurple,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _group == _AccountGroup.all,
                      isDark: isDark,
                      onTap: () => setState(() => _group = _AccountGroup.all),
                    ),
                    _FilterChip(
                      label: 'Cash',
                      selected: _group == _AccountGroup.cash,
                      isDark: isDark,
                      onTap: () => setState(() => _group = _AccountGroup.cash),
                    ),
                    _FilterChip(
                      label: 'Bank',
                      selected: _group == _AccountGroup.bank,
                      isDark: isDark,
                      onTap: () => setState(() => _group = _AccountGroup.bank),
                    ),
                    _FilterChip(
                      label: 'Custom',
                      selected: _group == _AccountGroup.custom,
                      isDark: isDark,
                      onTap: () => setState(() => _group = _AccountGroup.custom),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: accounts.isEmpty
                    ? _EmptyAccountsState(
                        isDark: isDark,
                        onAdd: _openAddAccountDialog,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: accounts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          final balance = accountProvider.balanceFor(
                            account.id,
                            txProvider.transactions,
                          );
                          final txCount = txProvider.transactions
                              .where((t) => t.accountId == account.id)
                              .length;
                          final isDefault = account.id == 'cash' || account.id == 'bank';

                          return InkWell(
                            onTap: () => _openAccountDetails(account),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (account.id == 'cash'
                                          ? AppColors.accentTeal
                                          : account.id == 'bank'
                                              ? AppColors.savingsBlue
                                              : AppColors.accentPurple)
                                      .withOpacity(isDark ? 0.18 : 0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: (account.id == 'cash'
                                              ? AppColors.accentTeal
                                              : account.id == 'bank'
                                                  ? AppColors.savingsBlue
                                                  : AppColors.accentPurple)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      account.id == 'cash'
                                          ? Icons.payments_rounded
                                          : account.id == 'bank'
                                              ? Icons.account_balance_rounded
                                              : Icons.account_balance_wallet_rounded,
                                      color: account.id == 'cash'
                                          ? AppColors.accentTeal
                                          : account.id == 'bank'
                                              ? AppColors.savingsBlue
                                              : AppColors.accentPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          account.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF172033),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$txCount transaction${txCount == 1 ? '' : 's'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.textSecondary
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(balance, currency),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF172033),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Opening ${CurrencyFormatter.format(account.initialBalance, currency)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.textSecondary
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    children: [
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: isDark ? Colors.white30 : Colors.grey[400],
                                      ),
                                      if (!isDefault)
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                          ),
                                          color: isDark ? Colors.white54 : Colors.grey[600],
                                          onPressed: () => _editAccountDialog(account),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryMiniCard extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final IconData icon;
  final Color accent;
  final bool isDark;

  const _SummaryMiniCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.formatCompact(amount, currency),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? AppColors.accentBlue
        : (isDark ? AppColors.darkCard : Colors.white);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.accentBlue
                    : (isDark ? Colors.white12 : Colors.grey.shade200),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.grey.shade700),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAccountsState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;

  const _EmptyAccountsState({required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 54, color: AppColors.accentBlue),
          const SizedBox(height: 12),
          Text(
            'No accounts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first account to track balances.',
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add account'),
          ),
        ],
      ),
    );
  }
}

class _AccountDetailsSheet extends StatelessWidget {
  final Account account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;

  const _AccountDetailsSheet({
    required this.account,
    required this.onEdit,
    required this.onDelete,
    required this.onAddIncome,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final currency = themeProvider.currency;
    final balance = accountProvider.balanceFor(account.id, txProvider.transactions);
    final transactions = txProvider.transactions
        .where((t) => t.accountId == account.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF172033),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Opening ${CurrencyFormatter.format(account.initialBalance, currency)}',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondary : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.gradientDarkStart, AppColors.gradientDarkEnd]
                        : [AppColors.gradientLightStart, AppColors.gradientLightEnd],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.format(balance, currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ActionPill(
                          label: 'Add income',
                          icon: Icons.add_rounded,
                          onTap: onAddIncome,
                        ),
                        _ActionPill(
                          label: 'Add expense',
                          icon: Icons.remove_rounded,
                          onTap: onAddExpense,
                        ),
                        if (account.id != 'cash' && account.id != 'bank')
                          _ActionPill(
                            label: 'Delete',
                            icon: Icons.delete_outline_rounded,
                            onTap: onDelete,
                            destructive: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF172033),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${transactions.length}',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondary : Colors.grey[600],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions in this account yet.',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondary : Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return TransactionTile(
                          transaction: tx,
                          currency: currency,
                          isDark: isDark,
                          onDelete: () => context.read<TransactionProvider>().deleteTransaction(tx.id),
                          onEdit: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => AddTransactionSheet(
                                initialType: tx.type,
                                transaction: tx,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionPill({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: destructive
              ? AppColors.expenseRed.withOpacity(0.15)
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: destructive
                ? AppColors.expenseRed.withOpacity(0.25)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: destructive ? AppColors.expenseRed : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: destructive ? AppColors.expenseRed : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
