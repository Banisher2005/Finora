import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/lending.dart';
import '../providers/account_provider.dart';
import '../providers/lending_provider.dart';
import '../providers/theme_provider.dart';
import '../themes/app_theme.dart';
import '../utils/app_utils.dart';

class LendingScreen extends StatefulWidget {
  const LendingScreen({super.key});

  @override
  State<LendingScreen> createState() => _LendingScreenState();
}

class _LendingScreenState extends State<LendingScreen> {
  bool _showSettled = false;

  Future<void> _openEntry({LendingEntry? entry}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LendingForm(entry: entry),
    );
  }

  Future<void> _repay(LendingEntry entry) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(entry.direction == LendingDirection.lent
            ? 'Record repayment'
            : 'Record payment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '${context.read<ThemeProvider>().currency} ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              double.tryParse(controller.text.replaceAll(',', '')),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (amount == null || amount <= 0 || !mounted) return;
    if (amount > entry.outstanding + 0.009) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cannot be greater than the outstanding amount.')),
      );
      return;
    }
    await context.read<LendingProvider>().markRepaid(entry, amount);
  }

  Future<void> _delete(LendingEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text('Remove the ${entry.person} lending record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expenseRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<LendingProvider>().deleteEntry(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LendingProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDarkMode;
    final currency = theme.currency;
    final entries = _showSettled
        ? provider.entries
        : provider.entries.where((e) => !e.isSettled).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntry(),
        backgroundColor: AppColors.accentBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add record', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lending',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Money you lent or borrowed',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondary : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _showSettled = !_showSettled),
                    tooltip: _showSettled ? 'Hide settled' : 'Show settled',
                    icon: Icon(
                      _showSettled ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'You will receive',
                      amount: provider.totalLentOutstanding,
                      currency: currency,
                      color: AppColors.incomeGreen,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'You owe',
                      amount: provider.totalBorrowedOutstanding,
                      currency: currency,
                      color: AppColors.expenseRed,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? _EmptyState(isDark: isDark, showSettled: _showSettled)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      itemCount: entries.length,
                      itemBuilder: (_, index) {
                        final entry = entries[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LendingCard(
                            entry: entry,
                            currency: currency,
                            isDark: isDark,
                            accountName: context.read<AccountProvider>().nameFor(entry.accountId),
                            onEdit: () => _openEntry(entry: entry),
                            onRepay: entry.isSettled ? null : () => _repay(entry),
                            onDelete: () => _delete(entry),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LendingForm extends StatefulWidget {
  final LendingEntry? entry;
  const _LendingForm({this.entry});

  @override
  State<_LendingForm> createState() => _LendingFormState();
}

class _LendingFormState extends State<_LendingForm> {
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _repaid = TextEditingController();
  final _note = TextEditingController();
  LendingDirection _direction = LendingDirection.lent;
  DateTime? _dueDate;
  String _accountId = 'cash';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (e != null) {
      _person.text = e.person;
      _amount.text = e.amount.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '');
      _repaid.text = e.repaidAmount.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '');
      _note.text = e.note;
      _direction = e.direction;
      _dueDate = e.dueDate;
      _accountId = e.accountId;
    }
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _repaid.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    final person = _person.text.trim();
    final amount = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    final repaid = double.tryParse(_repaid.text.replaceAll(',', '')) ?? 0;
    if (person.isEmpty || amount <= 0 || repaid < 0 || repaid > amount) return;

    setState(() => _saving = true);
    final provider = context.read<LendingProvider>();
    if (widget.entry == null) {
      await provider.addEntry(
        person: person,
        amount: amount,
        direction: _direction,
        accountId: _accountId,
        repaidAmount: repaid,
        dueDate: _dueDate,
        note: _note.text,
      );
    } else {
      final e = widget.entry!;
      e.person = person;
      e.amount = amount;
      e.repaidAmount = repaid;
      e.direction = _direction;
      e.accountId = _accountId;
      e.dueDate = _dueDate;
      e.note = _note.text.trim();
      await provider.updateEntry(e);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final isDark = theme.isDarkMode;
    final accounts = accountProvider.accounts;
    final validAccountId = accounts.any((a) => a.id == _accountId)
        ? _accountId
        : (accounts.isNotEmpty ? accounts.first.id : 'cash');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 20),
              Text(widget.entry == null ? 'Add lending record' : 'Edit lending record', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _DirectionChip(label: 'I lent money', icon: Icons.call_made_rounded, selected: _direction == LendingDirection.lent, color: AppColors.incomeGreen, onTap: () => setState(() => _direction = LendingDirection.lent))),
                  const SizedBox(width: 10),
                  Expanded(child: _DirectionChip(label: 'I borrowed', icon: Icons.call_received_rounded, selected: _direction == LendingDirection.borrowed, color: AppColors.expenseRed, onTap: () => setState(() => _direction = LendingDirection.borrowed))),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: _person, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Person / Name', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 12),
              TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.currency_rupee_rounded))),
              const SizedBox(height: 12),
              TextField(controller: _repaid, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Already paid / received', prefixIcon: Icon(Icons.check_circle_outline))),
              const SizedBox(height: 16),
              const Text('Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: accounts.map((a) => ChoiceChip(
                  label: Text(a.name),
                  selected: validAccountId == a.id,
                  onSelected: (_) => setState(() => _accountId = a.id),
                )).toList(),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Due date'),
                subtitle: Text(_dueDate == null ? 'No due date' : DateFormat('dd MMM yyyy').format(_dueDate!)),
                trailing: IconButton(onPressed: _pickDueDate, icon: const Icon(Icons.edit_calendar_outlined)),
              ),
              TextField(controller: _note, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Notes', alignLabelWithHint: true)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const CircularProgressIndicator(color: Colors.white) : Text(widget.entry == null ? 'Save record' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _DirectionChip({required this.label, required this.icon, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.14) : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: selected ? color : Colors.grey),
              const SizedBox(width: 7),
              Flexible(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? color : null))),
            ],
          ),
        ),
      );
}

class _LendingCard extends StatelessWidget {
  final LendingEntry entry;
  final String currency;
  final bool isDark;
  final String accountName;
  final VoidCallback onEdit;
  final VoidCallback? onRepay;
  final VoidCallback onDelete;

  const _LendingCard({required this.entry, required this.currency, required this.isDark, required this.accountName, required this.onEdit, required this.onRepay, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final lent = entry.direction == LendingDirection.lent;
    final color = lent ? AppColors.incomeGreen : AppColors.expenseRed;
    final progress = entry.amount == 0 ? 0.0 : (entry.repaidAmount / entry.amount).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEdit,
        onLongPress: onDelete,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(lent ? Icons.call_made_rounded : Icons.call_received_rounded, color: color)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(entry.person, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(lent ? 'They owe you' : 'You owe them', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(CurrencyFormatter.format(entry.outstanding, currency), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                    Text('of ${CurrencyFormatter.format(entry.amount, currency)}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[500])),
                  ]),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color))),
              const SizedBox(height: 9),
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 13, color: isDark ? Colors.white38 : Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(child: Text(accountName, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500]))),
                  if (entry.dueDate != null) Text('Due ${AppDateUtils.formatDateShort(entry.dueDate!)}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600])),
                  if (onRepay != null) ...[
                    const SizedBox(width: 8),
                    TextButton(onPressed: onRepay, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)), child: const Text('Repay')),
                  ] else const Text('Settled', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
              if (entry.note.isNotEmpty) ...[
                const SizedBox(height: 5),
                Align(alignment: Alignment.centerLeft, child: Text(entry.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  final bool isDark;
  const _SummaryCard({required this.label, required this.amount, required this.currency, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500])),
          const SizedBox(height: 5),
          FittedBox(child: Text(CurrencyFormatter.format(amount, currency), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color))),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final bool showSettled;
  const _EmptyState({required this.isDark, required this.showSettled});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.handshake_outlined, size: 56, color: isDark ? Colors.white24 : Colors.grey[300]),
          const SizedBox(height: 12),
          Text(showSettled ? 'No lending records yet' : 'Nothing outstanding', style: TextStyle(fontSize: 15, color: isDark ? Colors.white54 : Colors.grey[500])),
          const SizedBox(height: 6),
          Text('Tap + to track money you lend or borrow', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey[400])),
        ]),
      );
}
