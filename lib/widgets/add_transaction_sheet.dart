import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/account_provider.dart';
import '../themes/app_theme.dart';
import '../utils/app_utils.dart';

// ─── Indian number formatter ────────────────────────────────────────────────
class _IndianFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return newValue.copyWith(text: '');

    // Allow only digits + one decimal
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(raw)) return oldValue;

    final parts = raw.split('.');
    final intFormatted = _indCommas(parts[0]);
    final result = parts.length > 1
        ? '$intFormatted.${parts[1].length > 2 ? parts[1].substring(0, 2) : parts[1]}'
        : intFormatted;

    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }

  String _indCommas(String s) {
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final groups = <String>[];
    int i = rest.length;
    while (i > 0) {
      final start = i > 2 ? i - 2 : 0;
      groups.insert(0, rest.substring(start, i));
      i = start;
    }
    return '${groups.join(',')},${last3}';
  }
}

class AddTransactionSheet extends StatefulWidget {
  final TransactionType initialType;
  final DateTime? initialDate; // for previous-month CRUD

  const AddTransactionSheet({
    super.key,
    required this.initialType,
    this.initialDate,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late TransactionType _type;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = '';
  String _selectedSource = '';
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  double get _rawAmount {
    final clean = _amountController.text.replaceAll(',', '');
    return double.tryParse(clean) ?? 0;
  }

  String get _wordLabel {
    if (_rawAmount == 0) return '';
    final currency = '₹';
    return CurrencyFormatter.wordLabel(_rawAmount, currency);
  }

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedCategory = AppConstants.expenseCategories.first;
    _selectedSource = AppConstants.incomeCategories.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accentBlue,
            surface: AppColors.darkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accentBlue,
            surface: AppColors.darkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (_rawAmount <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final accId = context.read<AccountProvider>().activeAccountId;
    await context.read<TransactionProvider>().addTransaction(
          amount: _rawAmount,
          type: _type,
          category: _type == TransactionType.expense
              ? _selectedCategory
              : _selectedSource,
          source: _type == TransactionType.income
              ? _selectedSource
              : _selectedCategory,
          note: _noteController.text.trim(),
          date: _selectedDate,
          time: timeStr,
          accountId: accId,
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final currency = themeProvider.currency;
    final isIncome = _type == TransactionType.income;
    final accentColor = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20, top: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Type Toggle ───────────────────────────────
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _TypeTab(
                      label: 'Income',
                      isSelected: isIncome,
                      color: AppColors.incomeGreen,
                      isDark: isDark,
                      onTap: () => setState(() => _type = TransactionType.income),
                    ),
                    _TypeTab(
                      label: 'Expense',
                      isSelected: !isIncome,
                      color: AppColors.expenseRed,
                      isDark: isDark,
                      onTap: () => setState(() => _type = TransactionType.expense),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Amount ────────────────────────────────────
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondary : Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_IndianFormatter()],
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white24 : Colors.grey[400],
                  ),
                  prefixText: '$currency ',
                  prefixStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                autofocus: true,
              ),
              // ── Word label ───────────────────────────────
              if (_wordLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 2),
                  child: Text(
                    _wordLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: accentColor.withOpacity(0.7),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // ── Category / Source ─────────────────────────
              Text(
                isIncome ? 'Source' : 'Category',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondary : Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: (isIncome
                          ? AppConstants.incomeCategories
                          : AppConstants.expenseCategories)
                      .map((item) {
                    final isSelected = isIncome
                        ? _selectedSource == item
                        : _selectedCategory == item;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isIncome) {
                            _selectedSource = item;
                          } else {
                            _selectedCategory = item;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor
                              : (isDark
                                  ? AppColors.darkCard
                                  : const Color(0xFFF2F2F7)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.grey[600]),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // ── Date & Time ───────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: DateFormat('dd MMM yyyy').format(_selectedDate),
                      isDark: isDark,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.access_time_outlined,
                      label: 'Time',
                      value: _selectedTime.format(context),
                      isDark: isDark,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Notes ─────────────────────────────────────
              Text(
                'Notes (optional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondary : Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                ),
              ),
              const SizedBox(height: 28),

              // ── Save Button ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save ${isIncome ? 'Income' : 'Expense'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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

class _TypeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.grey[500]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textSecondary : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
