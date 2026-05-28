import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 3)
class Account extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue; // Store Color as int

  @HiveField(3)
  int iconCodePoint; // Store IconData as codePoint

  @HiveField(4)
  String accountType; // e.g. 'Personal', 'Business', 'Savings', 'Investment'

  @HiveField(5)
  DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.accountType,
    required this.createdAt,
  });
}
