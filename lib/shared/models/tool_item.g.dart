// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ToolItemAdapter extends TypeAdapter<ToolItem> {
  @override
  final int typeId = 2;

  @override
  ToolItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ToolItem(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      description: fields[3] as String,
      realWorldContext: fields[4] as String,
      level: fields[5] as int,
      stats: (fields[6] as Map?)?.cast<String, int>(),
      unlockedByLevelIds: (fields[7] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ToolItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.realWorldContext)
      ..writeByte(5)
      ..write(obj.level)
      ..writeByte(6)
      ..write(obj.stats)
      ..writeByte(7)
      ..write(obj.unlockedByLevelIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
