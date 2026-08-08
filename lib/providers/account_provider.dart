import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/hive_service.dart';
import '../models/account.dart';
import '../models/transaction.dart';

class AccountProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  List<Account> _accounts = [];

  List<Account> get accounts => List.unmodifiable(_accounts);

  AccountProvider() {
    loadAccounts();
  }

  void loadAccounts() {
    _accounts = HiveService.getAllAccounts();
    notifyListeners();
  }

  Account? byId(String id) {
    for (final account in _accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  String nameFor(String id) => byId(id)?.name ?? 'Cash';

  List<Account> get defaultAccounts =>
      _accounts.where((account) => account.id == 'cash' || account.id == 'bank').toList();

  List<Account> get customAccounts =>
      _accounts.where((account) => account.id != 'cash' && account.id != 'bank').toList();

  double totalBalance(List<Transaction> transactions) {
    return _accounts.fold(0, (sum, account) => sum + balanceFor(account.id, transactions));
  }

  double balanceFor(String accountId, List<Transaction> transactions) {
    final account = byId(accountId);
    var balance = account?.initialBalance ?? 0;
    for (final tx in transactions) {
      if (tx.accountId != accountId) continue;
      balance += tx.type == TransactionType.income ? tx.amount : -tx.amount;
    }
    return balance;
  }

  Future<void> addAccount(String name, {double initialBalance = 0}) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final account = Account(
      id: _uuid.v4(),
      name: clean,
      initialBalance: initialBalance,
      createdAt: DateTime.now(),
    );
    await HiveService.addAccount(account);
    loadAccounts();
  }

  Future<void> updateAccount(Account account) async {
    final clean = account.name.trim();
    if (clean.isEmpty) return;
    account.name = clean;
    await HiveService.updateAccount(account);
    loadAccounts();
  }

  Future<bool> deleteAccount(String id) async {
    if (id == 'cash' || id == 'bank') return false;
    if (HiveService.hasTransactionsForAccount(id) ||
        HiveService.hasLendingForAccount(id)) {
      return false;
    }
    await HiveService.deleteAccount(id);
    loadAccounts();
    return true;
  }
}
