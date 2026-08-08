import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/theme_provider.dart';
import '../providers/account_provider.dart';
import 'accounts_screen.dart';
import '../providers/lending_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/report_provider.dart';
import '../providers/security_provider.dart';
import '../database/hive_service.dart';
import '../themes/app_theme.dart';
import '../utils/app_utils.dart';

class SettingsScreen extends StatelessWidget {
  static const _filePickerChannel = MethodChannel('finora/file_picker');

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final securityProvider = context.watch<SecurityProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // ── Appearance ─────────────────────────────
                  _SectionHeader(label: 'Appearance', isDark: isDark),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _ToggleRow(
                        icon: Icons.dark_mode_outlined,
                        label: 'Dark Mode',
                        value: isDark,
                        isDark: isDark,
                        onChanged: (_) => themeProvider.toggleTheme(),
                      ),
                      _Divider(isDark: isDark),
                      _ToggleRow(
                        icon: Icons.fingerprint_rounded,
                        label: 'App Lock',
                        subtitle: 'Require biometric/PIN to open',
                        value: securityProvider.isLockEnabled,
                        isDark: isDark,
                        onChanged: (v) => securityProvider.setLockEnabled(v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Currency ────────────────────────────────
                  _SectionHeader(label: 'Currency', isDark: isDark),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _CurrencyRow(
                        current: themeProvider.currency,
                        isDark: isDark,
                        onSelect: (c) => themeProvider.setCurrency(c),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Accounts ─────────────────────────────────
                  _SectionHeader(label: 'Accounts', isDark: isDark),
                  const _AccountsCard(),
                  const SizedBox(height: 20),

                  // ── Data ────────────────────────────────────
                  _SectionHeader(label: 'Data', isDark: isDark),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _ActionRow(
                        icon: Icons.upload_outlined,
                        label: 'Export Backup',
                        iconColor: AppColors.accentBlue,
                        isDark: isDark,
                        onTap: () => _exportBackup(context),
                      ),
                      _Divider(isDark: isDark),
                      _ActionRow(
                        icon: Icons.download_outlined,
                        label: 'Import Backup',
                        iconColor: AppColors.incomeGreen,
                        isDark: isDark,
                        onTap: () => _importBackup(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Danger Zone ──────────────────────────────
                  _SectionHeader(label: 'Danger Zone', isDark: isDark),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _ActionRow(
                        icon: Icons.delete_forever_outlined,
                        label: 'Delete All Data',
                        iconColor: AppColors.expenseRed,
                        labelColor: AppColors.expenseRed,
                        isDark: isDark,
                        onTap: () => _confirmDelete(context, isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── About ────────────────────────────────────
                  _SectionHeader(label: 'About', isDark: isDark),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _InfoRow(
                        label: 'App Name',
                        value: 'Finora',
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _InfoRow(
                        label: 'Version',
                        value: '1.0.0',
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _InfoRow(
                        label: 'Storage',
                        value: 'Local only',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  Center(
                    child: Text(
                      'All your data stays on this device.\nNo cloud, no tracking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white24 : Colors.grey[400],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final data = HiveService.exportToJson();
      final json = jsonEncode(data);

      // Build a human-readable timestamped filename
      final now = DateTime.now();
      final ts =
          '${now.day.toString().padLeft(2, '0')}-${AppDateUtils.fullMonthName(now.month).substring(0, 3)}-${now.year}_'
          '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      final filename = 'finora_backup_$ts.json';

      // Prefer Android Downloads folder; fall back to app documents dir
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final saveDir = (await downloadsDir.exists())
          ? downloadsDir
          : await getApplicationDocumentsDirectory();

      final file = File('${saveDir.path}/$filename');
      await file.writeAsString(json);

      // Share so user can also send it somewhere
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Finora Backup — $ts',
      );

      if (context.mounted) {
        _showSnack(
          context,
          '✓ Saved to: ${saveDir.path}/$filename',
          AppColors.incomeGreen,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Export failed: $e', AppColors.expenseRed);
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final picked = await _filePickerChannel.invokeMethod<Map<dynamic, dynamic>>(
        'pickBackup',
      );
      if (picked == null) return;

      final rawBytes = picked['bytes'];
      if (rawBytes is! Uint8List && rawBytes is! List) {
        throw const FormatException('The selected file could not be read.');
      }

      final bytes = rawBytes is Uint8List
          ? rawBytes
          : Uint8List.fromList(List<int>.from(rawBytes));
      final jsonText = utf8.decode(bytes, allowMalformed: false);
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map) {
        throw const FormatException('This is not a valid Finora backup.');
      }

      final data = Map<String, dynamic>.from(decoded);
      final hasKnownSection = data.containsKey('transactions') ||
          data.containsKey('accounts') ||
          data.containsKey('lending') ||
          data.containsKey('reports');
      if (!hasKnownSection) {
        throw const FormatException('This file is not a Finora backup.');
      }

      await HiveService.importFromJson(data);

      if (context.mounted) {
        context.read<TransactionProvider>().loadTransactions();
        context.read<AccountProvider>().loadAccounts();
        context.read<LendingProvider>().loadEntries();
        context.read<ReportProvider>().loadReports();
        final name = picked['name']?.toString() ?? 'backup.json';
        _showSnack(context, '✓ Imported: $name', AppColors.incomeGreen);
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        _showSnack(
          context,
          'Import failed: ${e.message ?? e.code}',
          AppColors.expenseRed,
        );
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Import failed: ${e.message}', AppColors.expenseRed);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Import failed: $e', AppColors.expenseRed);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete All Data?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'This will permanently delete all your transactions and reports. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expenseRed),
            child: const Text('Delete All',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticFeedback.heavyImpact();
      await HiveService.deleteAllData();
      context.read<TransactionProvider>().loadTransactions();
      context.read<ReportProvider>().loadReports();
      if (context.mounted) {
        _showSnack(context, 'All data deleted', AppColors.expenseRed);
      }
    }
  }

  void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textSecondary : Colors.grey[500],
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accentPurple, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondary : Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accentBlue,
          ),
        ],
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  final String current;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const _CurrencyRow({
    required this.current,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.incomeGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.currency_exchange_outlined,
                    color: AppColors.incomeGreen, size: 18),
              ),
              const SizedBox(width: 14),
              Text(
                'Currency',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.currencies.map((c) {
              final isSelected = c == current;
              return GestureDetector(
                onTap: () => onSelect(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentBlue
                        : (isDark ? AppColors.darkCardElevated : const Color(0xFFF2F2F7)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      c,
                      style: TextStyle(
                        fontSize: 18,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600]),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color? labelColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.labelColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? (isDark ? Colors.white : const Color(0xFF1C1C1E)),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white30 : Colors.grey[300],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondary : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 66),
      child: Container(
        height: 1,
        color: isDark ? Colors.white10 : Colors.grey[100],
      ),
    );
  }
}

class _AccountsCard extends StatefulWidget {
  const _AccountsCard();

  @override
  State<_AccountsCard> createState() => _AccountsCardState();
}

class _AccountsCardState extends State<_AccountsCard> {
  Future<void> _addAccount() async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');

    final result = await showDialog<(String, double)?>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                hintText: 'e.g. Savings, UPI, Wallet',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Starting balance',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final balance = double.tryParse(balanceController.text.replaceAll(',', '')) ?? 0;
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
    await context.read<AccountProvider>().addAccount(result.$1, initialBalance: result.$2);
  }

  Future<void> _deleteAccount(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text(
          'An account can only be deleted when it has no transactions or lending records.',
        ),
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
    if (ok != true || !mounted) return;
    final deleted = await context.read<AccountProvider>().deleteAccount(id);
    if (!deleted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This account is in use and cannot be deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDarkMode;

    return _SettingsCard(
      isDark: isDark,
      children: [
        ...provider.accounts.asMap().entries.map((entry) {
          final account = entry.value;
          final balance = provider.balanceFor(account.id, txProvider.transactions);
          final isLast = entry.key == provider.accounts.length - 1;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccountsScreen(initialFocusAccountId: account.id),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: AppColors.accentBlue.withOpacity(0.12),
                  child: Icon(
                    account.name.toLowerCase().contains('cash')
                        ? Icons.payments_outlined
                        : Icons.account_balance_outlined,
                    color: AppColors.accentBlue,
                  ),
                ),
                title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${theme.currency}${balance.toStringAsFixed(2)} available',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[500]),
                ),
                trailing: (account.id == 'cash' || account.id == 'bank')
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.expenseRed,
                        onPressed: () => _deleteAccount(account.id, account.name),
                      ),
              ),
              if (!isLast) _Divider(isDark: isDark),
            ],
          );
        }),
        _Divider(isDark: isDark),
        _ActionRow(
          icon: Icons.add_circle_outline,
          label: 'Add Account',
          iconColor: AppColors.accentBlue,
          isDark: isDark,
          onTap: _addAccount,
        ),
      ],
    );
  }
}
