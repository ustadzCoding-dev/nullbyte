// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 4;

  @override
  Achievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Achievement(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      isSecret: fields[3] as bool,
      conditionType: fields[4] as String,
      conditionValue: fields[5] as int,
      bonusPoints: fields[6] as int,
      isUnlocked: fields[7] as bool,
      unlockedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isSecret)
      ..writeByte(4)
      ..write(obj.conditionType)
      ..writeByte(5)
      ..write(obj.conditionValue)
      ..writeByte(6)
      ..write(obj.bonusPoints)
      ..writeByte(7)
      ..write(obj.isUnlocked)
      ..writeByte(8)
      ..write(obj.unlockedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
