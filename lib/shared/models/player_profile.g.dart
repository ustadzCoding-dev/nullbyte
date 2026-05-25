// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerProfileAdapter extends TypeAdapter<PlayerProfile> {
  @override
  final int typeId = 0;

  @override
  PlayerProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerProfile(
      id: fields[0] as String,
      username: fields[1] as String,
      email: fields[2] as String?,
      isGuest: fields[3] as bool,
      totalScore: fields[4] as int,
      level: fields[5] as int,
      xp: fields[6] as int,
      createdAt: fields[7] as DateTime,
      lastSyncAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerProfile obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.isGuest)
      ..writeByte(4)
      ..write(obj.totalScore)
      ..writeByte(5)
      ..write(obj.level)
      ..writeByte(6)
      ..write(obj.xp)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.lastSyncAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
