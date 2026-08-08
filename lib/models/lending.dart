import 'package:hive/hive.dart';

part 'lending.g.dart';

@HiveType(typeId: 6)
enum LendingDirection {
  @HiveField(0)
  lent,
  @HiveField(1)
  borrowed,
}

@HiveType(typeId: 7)
class LendingEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String person;

  @HiveField(2)
  double amount;

  @HiveField(3)
  double repaidAmount;

  @HiveField(4)
  LendingDirection direction;

  @HiveField(5)
  DateTime? dueDate;

  @HiveField(6)
  String note;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String accountId;

  LendingEntry({
    required this.id,
    required this.person,
    required this.amount,
    this.repaidAmount = 0,
    required this.direction,
    this.dueDate,
    this.note = '',
    required this.createdAt,
    required this.accountId,
  });

  double get outstanding => (amount - repaidAmount).clamp(0, amount).toDouble();
  bool get isSettled => outstanding <= 0.009;
}
