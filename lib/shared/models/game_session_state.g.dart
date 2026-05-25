// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_session_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameSessionStateAdapter extends TypeAdapter<GameSessionState> {
  @override
  final int typeId = 1;

  @override
  GameSessionState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameSessionState(
      levelId: fields[0] as String,
      startTime: fields[1] as DateTime,
      hintsUsed: fields[2] as int,
      failedAttempts: fields[3] as int,
      commandHistory: (fields[4] as List?)?.cast<String>(),
      nodeStates: (fields[5] as Map?)?.cast<String, String>(),
      isCompleted: fields[6] as bool,
      finalScore: fields[7] as int?,
      lives: fields[8] as int,
      elapsedSeconds: fields[9] as int,
      currentDirectory: fields[10] as String,
      currentUser: fields[11] as String,
      hasRootPrivilege: fields[12] as bool,
      completedObjectives: (fields[13] as List?)?.cast<String>(),
      currentHost: fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GameSessionState obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.levelId)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.hintsUsed)
      ..writeByte(3)
      ..write(obj.failedAttempts)
      ..writeByte(4)
      ..write(obj.commandHistory)
      ..writeByte(5)
      ..write(obj.nodeStates)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.finalScore)
      ..writeByte(8)
      ..write(obj.lives)
      ..writeByte(9)
      ..write(obj.elapsedSeconds)
      ..writeByte(10)
      ..write(obj.currentDirectory)
      ..writeByte(11)
      ..write(obj.currentUser)
      ..writeByte(12)
      ..write(obj.hasRootPrivilege)
      ..writeByte(13)
      ..write(obj.completedObjectives)
      ..writeByte(14)
      ..write(obj.currentHost);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSessionStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
