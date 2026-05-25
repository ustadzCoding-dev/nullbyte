// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_progress_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LevelProgressDataAdapter extends TypeAdapter<LevelProgressData> {
  @override
  final int typeId = 5;

  @override
  LevelProgressData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LevelProgressData(
      levelId: fields[0] as String,
      isCompleted: fields[1] as bool,
      bestScore: fields[2] as int,
      bestTime: fields[3] as int,
      starsEarned: fields[4] as int,
      hintsUsed: fields[5] as int,
      completedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LevelProgressData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.levelId)
      ..writeByte(1)
      ..write(obj.isCompleted)
      ..writeByte(2)
      ..write(obj.bestScore)
      ..writeByte(3)
      ..write(obj.bestTime)
      ..writeByte(4)
      ..write(obj.starsEarned)
      ..writeByte(5)
      ..write(obj.hintsUsed)
      ..writeByte(6)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelProgressDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
