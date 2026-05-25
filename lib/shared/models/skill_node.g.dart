// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_node.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SkillNodeAdapter extends TypeAdapter<SkillNode> {
  @override
  final int typeId = 3;

  @override
  SkillNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SkillNode(
      id: fields[0] as String,
      domain: fields[1] as String,
      name: fields[2] as String,
      description: fields[3] as String,
      xpRequired: fields[4] as int,
      prerequisiteIds: (fields[5] as List?)?.cast<String>(),
      unlocksToolId: fields[6] as String?,
      bonuses: (fields[7] as Map?)?.cast<String, dynamic>(),
      isUnlocked: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SkillNode obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.domain)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.xpRequired)
      ..writeByte(5)
      ..write(obj.prerequisiteIds)
      ..writeByte(6)
      ..write(obj.unlocksToolId)
      ..writeByte(7)
      ..write(obj.bonuses)
      ..writeByte(8)
      ..write(obj.isUnlocked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
