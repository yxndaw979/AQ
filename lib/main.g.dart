// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AiMemoryAdapter extends TypeAdapter<AiMemory> {
  @override
  final int typeId = 2;

  @override
  AiMemory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiMemory(
      content: fields[0] as String,
      createTime: fields[1] as DateTime,
      importance: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AiMemory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.content)
      ..writeByte(1)
      ..write(obj.createTime)
      ..writeByte(2)
      ..write(obj.importance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiMemoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatSessionAdapter extends TypeAdapter<ChatSession> {
  @override
  final int typeId = 0;

  @override
  ChatSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatSession(
      id: fields[0] as String,
      title: fields[1] as String,
      previewText: fields[2] as String,
      timeLabel: fields[3] as String,
      unreadCount: fields[4] as int,
      favorValue: fields[5] as int,
      persona: fields[7] as String,
      messages: (fields[6] as List?)?.cast<ChatMessage>(),
      memoryList: (fields[8] as List?)?.cast<AiMemory>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatSession obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.previewText)
      ..writeByte(3)
      ..write(obj.timeLabel)
      ..writeByte(4)
      ..write(obj.unreadCount)
      ..writeByte(5)
      ..write(obj.favorValue)
      ..writeByte(6)
      ..write(obj.messages)
      ..writeByte(7)
      ..write(obj.persona)
      ..writeByte(8)
      ..write(obj.memoryList);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 1;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      isUser: fields[0] as bool,
      content: fields[1] as String,
      time: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.isUser)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.time);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
