import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/hive_service.dart';
import '../models/lending.dart';

class LendingProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  List<LendingEntry> _entries = [];

  List<LendingEntry> get entries => List.unmodifiable(_entries);
  List<LendingEntry> get outstanding =>
      _entries.where((e) => !e.isSettled).toList();

  double get totalLentOutstanding => _entries
      .where((e) => e.direction == LendingDirection.lent && !e.isSettled)
      .fold(0, (s, e) => s + e.outstanding);

  double get totalBorrowedOutstanding => _entries
      .where((e) => e.direction == LendingDirection.borrowed && !e.isSettled)
      .fold(0, (s, e) => s + e.outstanding);

  LendingProvider() {
    loadEntries();
  }

  void loadEntries() {
    _entries = HiveService.getAllLendingEntries();
    notifyListeners();
  }

  Future<void> addEntry({
    required String person,
    required double amount,
    required LendingDirection direction,
    required String accountId,
    double repaidAmount = 0,
    DateTime? dueDate,
    String note = '',
  }) async {
    final entry = LendingEntry(
      id: _uuid.v4(),
      person: person.trim(),
      amount: amount,
      repaidAmount: repaidAmount.clamp(0, amount).toDouble(),
      direction: direction,
      dueDate: dueDate,
      note: note.trim(),
      createdAt: DateTime.now(),
      accountId: accountId,
    );
    await HiveService.addLendingEntry(entry);
    loadEntries();
  }

  Future<void> updateEntry(LendingEntry entry) async {
    entry.repaidAmount = entry.repaidAmount.clamp(0, entry.amount).toDouble();
    await HiveService.updateLendingEntry(entry);
    loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await HiveService.deleteLendingEntry(id);
    loadEntries();
  }

  Future<void> markRepaid(LendingEntry entry, double amount) async {
    entry.repaidAmount = (entry.repaidAmount + amount)
        .clamp(0, entry.amount)
        .toDouble();
    await updateEntry(entry);
  }
}
