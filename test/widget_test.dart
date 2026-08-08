import 'package:flutter_test/flutter_test.dart';

import 'package:finora/models/lending.dart';
import 'package:finora/models/transaction.dart';

void main() {
  test('transaction supports account and optional image', () {
    final tx = Transaction(
      id: 'test',
      amount: 500,
      type: TransactionType.expense,
      category: 'Food',
      source: 'Food',
      date: DateTime(2026, 8, 8),
      time: '12:00',
      createdAt: DateTime(2026, 8, 8),
      accountId: 'cash',
      imagePath: '/tmp/receipt.jpg',
    );

    expect(tx.accountId, 'cash');
    expect(tx.imagePath, '/tmp/receipt.jpg');
  });

  test('lending outstanding balance is calculated correctly', () {
    final entry = LendingEntry(
      id: 'loan-1',
      person: 'Test Person',
      amount: 5000,
      repaidAmount: 1500,
      direction: LendingDirection.lent,
      accountId: 'cash',
      createdAt: DateTime(2026, 8, 8),
    );

    expect(entry.outstanding, 3500);
    expect(entry.isSettled, isFalse);
  });
}
