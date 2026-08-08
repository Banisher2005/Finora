import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/account_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../themes/app_theme.dart';
import '../utils/app_utils.dart';

class _IndianFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return newValue.copyWith(text: '');
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
    return '${groups.join(',')},$last3';
  }
}

class AddTransactionSheet extends StatefulWidget {
  final TransactionType initialType;
  final DateTime? initialDate;
  final Transaction? transaction;

  const AddTransactionSheet({
    super.key,
    required this.initialType,
    this.initialDate,
    this.transaction,
  });

  bool get isEditing => transaction != null;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  static const _uuid = Uuid();
  final _imagePicker = ImagePicker();

  late TransactionType _type;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = '';
  String _selectedSource = '';
  String _selectedAccountId = 'cash';
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _imagePath;
  bool _isLoading = false;

  double get _rawAmount =>
      double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

  String get _wordLabel {
    if (_rawAmount == 0) return '';
    return CurrencyFormatter.wordLabel(_rawAmount, '₹');
  }

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _type = tx?.type ?? widget.initialType;

    if (tx != null) {
      _amountController.text = _formatAmountForInput(tx.amount);
      _noteController.text = tx.note;
      _selectedCategory = tx.category;
      _selectedSource = tx.source;
      _selectedAccountId = tx.accountId;
      _selectedDate = tx.date;
      _selectedTime = _parseTime(tx.time);
      _imagePath = tx.imagePath;
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedTime = TimeOfDay.now();
      _selectedCategory = AppConstants.expenseCategories.first;
      _selectedSource = AppConstants.incomeCategories.first;
    }
  }

  String _formatAmountForInput(double amount) {
    if (amount == amount.roundToDouble()) return amount.toInt().toString();
    return amount.toStringAsFixed(2);
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return TimeOfDay.now();
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? TimeOfDay.now().hour,
      minute: int.tryParse(parts[1]) ?? TimeOfDay.now().minute,
    );
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
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1800,
      );
      if (picked == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${dir.path}/transaction_images');
      await imageDir.create(recursive: true);
      final extension = picked.path.contains('.')
          ? picked.path.split('.').last.toLowerCase()
          : 'jpg';
      final target = File(
        '${imageDir.path}/${_uuid.v4()}.$extension',
      );
      await File(picked.path).copy(target.path);

      final oldPath = _imagePath;
      setState(() => _imagePath = target.path);
      if (oldPath != null && oldPath != target.path) {
        await _deleteImageFile(oldPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add image: $e')),
        );
      }
    }
  }

  Future<void> _deleteImageFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _removeImage() async {
    final path = _imagePath;
    setState(() => _imagePath = null);
    await _deleteImageFile(path);
  }

  Future<void> _addAccount() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add account'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Savings, UPI, Wallet'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty || !mounted) return;
    await context.read<AccountProvider>().addAccount(name);
    if (!mounted) return;
    final accounts = context.read<AccountProvider>().accounts;
    final added = accounts.where((a) => a.name == name).toList();
    if (added.isNotEmpty) setState(() => _selectedAccountId = added.last.id);
  }

  Future<void> _save() async {
    if (_rawAmount <= 0 || _noteController.text.trim().length > 2000) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final category = _type == TransactionType.expense
        ? _selectedCategory
        : _selectedSource;
    final source = _type == TransactionType.income
        ? _selectedSource
        : _selectedCategory;

    final provider = context.read<TransactionProvider>();
    if (widget.transaction == null) {
      await provider.addTransaction(
        amount: _rawAmount,
        type: _type,
        category: category,
        source: source,
        note: _noteController.text.trim(),
        date: _selectedDate,
        time: timeStr,
        accountId: _selectedAccountId,
        imagePath: _imagePath,
      );
    } else {
      final tx = widget.transaction!;
      tx.amount = _rawAmount;
      tx.type = _type;
      tx.category = category;
      tx.source = source;
      tx.note = _noteController.text.trim();
      tx.date = _selectedDate;
      tx.time = timeStr;
      tx.accountId = _selectedAccountId;
      tx.imagePath = _imagePath;
      await provider.updateTransaction(tx);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final isDark = themeProvider.isDarkMode;
    final currency = themeProvider.currency;
    final isIncome = _type == TransactionType.income;
    final accentColor = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    final accounts = accountProvider.accounts;

    final selectedAccountId = accounts.any((a) => a.id == _selectedAccountId)
        ? _selectedAccountId
        : (accounts.isNotEmpty ? accounts.first.id : 'cash');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Text(
                widget.isEditing ? 'Edit Transaction' : 'New Transaction',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 16),
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
                      onTap: () => setState(() {
                        _type = TransactionType.income;
                        _selectedSource = AppConstants.incomeCategories.first;
                      }),
                    ),
                    _TypeTab(
                      label: 'Expense',
                      isSelected: !isIncome,
                      color: AppColors.expenseRed,
                      isDark: isDark,
                      onTap: () => setState(() {
                        _type = TransactionType.expense;
                        _selectedCategory = AppConstants.expenseCategories.first;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _FieldLabel('Amount', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_IndianFormatter()],
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: '$currency ',
                  prefixStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
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
              _FieldLabel(isIncome ? 'Source' : 'Category', isDark),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: (isIncome
                          ? AppConstants.incomeCategories
                          : AppConstants.expenseCategories)
                      .map((item) {
                    final selected = isIncome
                        ? _selectedSource == item
                        : _selectedCategory == item;
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (isIncome) {
                          _selectedSource = item;
                        } else {
                          _selectedCategory = item;
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? accentColor
                              : (isDark ? AppColors.darkCard : const Color(0xFFF2F2F7)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
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
              _FieldLabel('Account', isDark),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...accounts.map((account) => _AccountChip(
                          account: account,
                          selected: selectedAccountId == account.id,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedAccountId = account.id),
                        )),
                    GestureDetector(
                      onTap: _addAccount,
                      child: Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.grey[300]!,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_rounded, size: 17),
                            SizedBox(width: 4),
                            Text('Add account'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
              _FieldLabel('Description / Notes', isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
                decoration: const InputDecoration(
                  hintText: 'What was this for? Add as much detail as you need...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              _AttachmentCard(
                imagePath: _imagePath,
                isDark: isDark,
                onAdd: _pickImage,
                onRemove: _removeImage,
              ),
              const SizedBox(height: 28),
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
                          widget.isEditing
                              ? 'Save Changes'
                              : 'Save ${isIncome ? 'Income' : 'Expense'}',
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

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSecondary : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      );
}

class _AccountChip extends StatelessWidget {
  final Account account;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _AccountChip({
    required this.account,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentBlue
              : (isDark ? AppColors.darkCard : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              account.name.toLowerCase().contains('cash')
                  ? Icons.payments_outlined
                  : Icons.account_balance_outlined,
              size: 17,
              color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Text(
              account.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final String? imagePath;
  final bool isDark;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _AttachmentCard({
    required this.imagePath,
    required this.isDark,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    return Container(
      height: hasImage ? 150 : 64,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 32),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _CircleAction(icon: Icons.edit_outlined, onTap: onAdd),
                      const SizedBox(width: 8),
                      _CircleAction(icon: Icons.delete_outline, onTap: onRemove),
                    ],
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: onAdd,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined),
                  SizedBox(width: 8),
                  Text(
                    'Add receipt / photo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      );
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
            Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
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
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
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
}
