// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordRecordAdapter extends TypeAdapter<WordRecord> {
  @override
  final int typeId = 0;

  @override
  WordRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WordRecord(
      word: fields[0] as String,
      level: fields[1] as String,
      lastSeen: fields[2] as DateTime,
      successCount: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WordRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.word)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.lastSeen)
      ..writeByte(3)
      ..write(obj.successCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
