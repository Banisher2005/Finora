import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 5)
class Account extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double initialBalance;

  @HiveField(3)
  DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    this.initialBalance = 0,
    required this.createdAt,
  });
}
