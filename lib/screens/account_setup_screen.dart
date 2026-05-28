import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/account_provider.dart';
import '../themes/app_theme.dart';

class AccountSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;
  const AccountSetupScreen({super.key, required this.onSetupComplete});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final _nameController = TextEditingController(text: 'Personal');
  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;
  int _selectedTypeIndex = 0;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isCreating = true);
    HapticFeedback.mediumImpact();

    final provider = context.read<AccountProvider>();
    final color = AccountProvider.accountColors[_selectedColorIndex];
    final iconData =
        AccountProvider.accountIcons[_selectedIconIndex]['icon'] as IconData;
    final type =
        AccountProvider.accountTypes[_selectedTypeIndex]['label'] as String;

    await provider.addAccount(
      name: _nameController.text.trim(),
      colorValue: color.value,
      iconCodePoint: iconData.codePoint,
      accountType: type,
    );

    if (mounted) widget.onSetupComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // ── Logo ─────────────────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentBlue, Color(0xFF5E5CE6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBlue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              // ── Title ────────────────────────────────────
              Center(
                child: Text(
                  'Welcome to Finora',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Let\'s set up your first account',
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          isDark ? AppColors.textSecondary : Colors.grey[600],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

              const SizedBox(height: 36),

              // ── Account Name ─────────────────────────────
              _SectionLabel(label: 'Account Name', isDark: isDark),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Personal, Business...',
                  prefixIcon: Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.grey[400],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Account Type ─────────────────────────────
              _SectionLabel(label: 'Account Type', isDark: isDark),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AccountProvider.accountTypes
                    .asMap()
                    .entries
                    .map((entry) {
                  final i = entry.key;
                  final type = entry.value;
                  final isSelected = i == _selectedTypeIndex;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTypeIndex = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentBlue
                            : (isDark
                                ? AppColors.darkCard
                                : const Color(0xFFF2F2F7)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentBlue
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.grey[600]),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            type['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white70
                                      : Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── Color ────────────────────────────────────
              _SectionLabel(label: 'Color', isDark: isDark),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: AccountProvider.accountColors
                    .asMap()
                    .entries
                    .map((entry) {
                  final i = entry.key;
                  final color = entry.value;
                  final isSelected = i == _selectedColorIndex;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedColorIndex = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 36 : 30,
                      height: isSelected ? 36 : 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── Icon ─────────────────────────────────────
              _SectionLabel(label: 'Icon', isDark: isDark),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: AccountProvider.accountIcons
                    .asMap()
                    .entries
                    .map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isSelected = i == _selectedIconIndex;
                  final selectedColor =
                      AccountProvider.accountColors[_selectedColorIndex];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedIconIndex = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor.withOpacity(0.15)
                            : (isDark
                                ? AppColors.darkCard
                                : const Color(0xFFF2F2F7)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? selectedColor
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        size: 18,
                        color: isSelected
                            ? selectedColor
                            : (isDark ? Colors.white38 : Colors.grey[500]),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // ── Preview ──────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AccountProvider
                              .accountColors[_selectedColorIndex]
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          AccountProvider.accountIcons[_selectedIconIndex]
                              ['icon'] as IconData,
                          color: AccountProvider
                              .accountColors[_selectedColorIndex],
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty
                                ? 'Account'
                                : _nameController.text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E),
                            ),
                          ),
                          Text(
                            AccountProvider.accountTypes[_selectedTypeIndex]
                                ['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Create Button ────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AccountProvider.accountColors[_selectedColorIndex],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Account & Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 600.ms),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: isDark ? AppColors.textSecondary : Colors.grey[500],
      ),
    );
  }
}
