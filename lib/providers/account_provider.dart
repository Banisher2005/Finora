import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../database/hive_service.dart';
import '../models/account.dart';

class AccountProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  List<Account> _accounts = [];
  String _activeAccountId = '';
  bool _setupDone = false;

  List<Account> get accounts => _accounts;
  String get activeAccountId => _activeAccountId;
  bool get setupDone => _setupDone;

  Account? get activeAccount {
    try {
      return _accounts.firstWhere((a) => a.id == _activeAccountId);
    } catch (_) {
      return _accounts.isNotEmpty ? _accounts.first : null;
    }
  }

  AccountProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _setupDone = prefs.getBool('account_setup_done') ?? false;
    _activeAccountId = prefs.getString('active_account_id') ?? '';
    loadAccounts();
  }

  void loadAccounts() {
    _accounts = HiveService.getAllAccounts();

    // If active account doesn't exist, pick the first one
    if (_accounts.isNotEmpty &&
        !_accounts.any((a) => a.id == _activeAccountId)) {
      _activeAccountId = _accounts.first.id;
      _persistActiveAccount();
    }

    notifyListeners();
  }

  Future<void> setActiveAccount(String id) async {
    _activeAccountId = id;
    await _persistActiveAccount();
    notifyListeners();
  }

  Future<void> _persistActiveAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_account_id', _activeAccountId);
  }

  Future<Account> addAccount({
    required String name,
    required int colorValue,
    required int iconCodePoint,
    required String accountType,
  }) async {
    final account = Account(
      id: _uuid.v4(),
      name: name,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      accountType: accountType,
      createdAt: DateTime.now(),
    );
    await HiveService.addAccount(account);

    // If this is the first account, set it active and mark setup done
    if (_accounts.isEmpty) {
      _activeAccountId = account.id;
      await _persistActiveAccount();
      await markSetupDone();
    }

    loadAccounts();
    return account;
  }

  Future<void> updateAccount({
    required String id,
    required String name,
    required int colorValue,
    required int iconCodePoint,
    required String accountType,
  }) async {
    final existing = HiveService.getAccount(id);
    if (existing == null) return;

    existing.name = name;
    existing.colorValue = colorValue;
    existing.iconCodePoint = iconCodePoint;
    existing.accountType = accountType;
    await HiveService.updateAccount(existing);
    loadAccounts();
  }

  Future<void> removeAccount(String id) async {
    if (_accounts.length <= 1) return; // Can't delete last account
    await HiveService.deleteAccount(id);

    if (_activeAccountId == id) {
      _activeAccountId = '';
    }
    loadAccounts();
  }

  Future<void> markSetupDone() async {
    _setupDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('account_setup_done', true);
    notifyListeners();
  }

  // ── Preset options for the account setup ──────────────────────

  static const List<Map<String, dynamic>> accountTypes = [
    {'label': 'Personal', 'icon': Icons.person_outline_rounded},
    {'label': 'Business', 'icon': Icons.business_center_outlined},
    {'label': 'Savings', 'icon': Icons.savings_outlined},
    {'label': 'Investment', 'icon': Icons.trending_up_rounded},
    {'label': 'Family', 'icon': Icons.family_restroom_rounded},
    {'label': 'Other', 'icon': Icons.account_balance_wallet_outlined},
  ];

  static const List<Color> accountColors = [
    Color(0xFF0A84FF), // Blue
    Color(0xFF34C759), // Green
    Color(0xFFFF9F0A), // Orange
    Color(0xFFFF375F), // Pink
    Color(0xFF5E5CE6), // Purple
    Color(0xFF32ADE6), // Cyan
    Color(0xFFFF6961), // Coral
    Color(0xFFBF5AF2), // Violet
    Color(0xFFFFD60A), // Yellow
    Color(0xFF30D158), // Mint
  ];

  static const List<Map<String, dynamic>> accountIcons = [
    {'icon': Icons.account_balance_wallet_rounded, 'label': 'Wallet'},
    {'icon': Icons.account_balance_rounded, 'label': 'Bank'},
    {'icon': Icons.credit_card_rounded, 'label': 'Card'},
    {'icon': Icons.savings_rounded, 'label': 'Piggy'},
    {'icon': Icons.business_center_rounded, 'label': 'Business'},
    {'icon': Icons.store_rounded, 'label': 'Store'},
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.school_rounded, 'label': 'Education'},
    {'icon': Icons.favorite_rounded, 'label': 'Personal'},
    {'icon': Icons.diamond_rounded, 'label': 'Premium'},
  ];
}
