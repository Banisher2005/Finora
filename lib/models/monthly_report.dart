import 'package:hive/hive.dart';

part 'monthly_report.g.dart';

@HiveType(typeId: 2)
class MonthlyReport extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int month;

  @HiveField(2)
  int year;

  @HiveField(3)
  double totalIncome;

  @HiveField(4)
  double totalExpense;

  @HiveField(5)
  double savings;

  @HiveField(6)
  DateTime generatedAt;

  @HiveField(7)
  Map<String, double> expenseBreakdown;

  @HiveField(8)
  Map<String, double> incomeBreakdown;

  MonthlyReport({
    required this.id,
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    required this.savings,
    required this.generatedAt,
    required this.expenseBreakdown,
    required this.incomeBreakdown,
  });
}
