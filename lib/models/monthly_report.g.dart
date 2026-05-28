// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonthlyReportAdapter extends TypeAdapter<MonthlyReport> {
  @override
  final int typeId = 2;

  @override
  MonthlyReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlyReport(
      id: fields[0] as String,
      month: fields[1] as int,
      year: fields[2] as int,
      totalIncome: fields[3] as double,
      totalExpense: fields[4] as double,
      savings: fields[5] as double,
      generatedAt: fields[6] as DateTime,
      expenseBreakdown: (fields[7] as Map).cast<String, double>(),
      incomeBreakdown: (fields[8] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, MonthlyReport obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.month)
      ..writeByte(2)
      ..write(obj.year)
      ..writeByte(3)
      ..write(obj.totalIncome)
      ..writeByte(4)
      ..write(obj.totalExpense)
      ..writeByte(5)
      ..write(obj.savings)
      ..writeByte(6)
      ..write(obj.generatedAt)
      ..writeByte(7)
      ..write(obj.expenseBreakdown)
      ..writeByte(8)
      ..write(obj.incomeBreakdown);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
