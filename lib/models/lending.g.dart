// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lending.dart';

class LendingDirectionAdapter extends TypeAdapter<LendingDirection> {
  @override
  final int typeId = 6;

  @override
  LendingDirection read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LendingDirection.lent;
      case 1:
        return LendingDirection.borrowed;
      default:
        return LendingDirection.lent;
    }
  }

  @override
  void write(BinaryWriter writer, LendingDirection obj) {
    switch (obj) {
      case LendingDirection.lent:
        writer.writeByte(0);
        break;
      case LendingDirection.borrowed:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LendingDirectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LendingEntryAdapter extends TypeAdapter<LendingEntry> {
  @override
  final int typeId = 7;

  @override
  LendingEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LendingEntry(
      id: fields[0] as String,
      person: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      repaidAmount: (fields[3] as num?)?.toDouble() ?? 0,
      direction: fields[4] as LendingDirection,
      dueDate: fields[5] as DateTime?,
      note: fields[6] as String? ?? '',
      createdAt: fields[7] as DateTime? ?? DateTime.now(),
      accountId: fields[8] as String? ?? 'cash',
    );
  }

  @override
  void write(BinaryWriter writer, LendingEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.person)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.repaidAmount)
      ..writeByte(4)
      ..write(obj.direction)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.accountId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LendingEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
