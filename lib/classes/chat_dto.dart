import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/uuid.dart';

abstract class ChatDTO {
  final UUID id;
  final ChatMessageWrapperDTO lastMessage;
  final UUID? avatarID;

  static ChatDTO fromMap(client, obj) {
    final map = Map<String, dynamic>.from(obj);

    final String type = map["chat"]["type"]!;
    return switch (type) {
      "gr" => GroupDTO.fromMap(client, map),
      "dl" => DialogDTO.fromMap(client, map),
      _ => throw ErrorDescription('Unexpected type "$type", - "gr", "dl"')
    };
  }

  ChatDTO({
    required this.id,
    required this.lastMessage,
    required this.avatarID,
  });

  String getTitle();
}

class GroupDTO extends ChatDTO {
  final String title;
  final String owner;

  GroupDTO({
    required super.id,
    required super.lastMessage,
    required super.avatarID,
    required this.title,
    required this.owner,
  });

  factory GroupDTO.fromMap(Client client, Map<String, dynamic> obj) {
    final chatMap = obj["chat"]!;
    return GroupDTO(
      id: UUID.fromString(chatMap["id"]),
      lastMessage: ChatMessageWrapperDTO(
        ChatMessageViewDTO.fromMap(client, chatMap["last-message"]),
        obj["decrypted-last-message"],
      ),
      avatarID: UUID.fromNullableString(chatMap["avatar"]),
      title: chatMap["group-title"]!,
      owner: chatMap["group-owner"]!,
    );
  }

  @override
  String getTitle() {
    return title;
  }

  @override
  String toString() {
    return "Group{id=$id title=$title}";
  }
}

class DialogDTO extends ChatDTO {
  final String otherNickname;
  final bool isMonolog;

  DialogDTO({
    required super.id,
    required super.lastMessage,
    required super.avatarID,
    required this.otherNickname,
    required this.isMonolog,
  });

  factory DialogDTO.fromMap(Client client, Map<String, dynamic> obj) {
    final chatMap = obj["chat"]!;
    final String otherNickname = chatMap["dialog-other"]!;
    return DialogDTO(
      id: UUID.fromString(chatMap["id"]),
      lastMessage: ChatMessageWrapperDTO(
        ChatMessageViewDTO.fromMap(client, chatMap['last-message']),
        obj["decrypted-last-message"],
      ),
      avatarID: UUID.fromNullableString(chatMap["avatar"]),
      otherNickname: otherNickname,
      isMonolog: client.user!.nickname == otherNickname,
    );
  }

  @override
  String getTitle() {
    return isMonolog ? "Monolog" : otherNickname;
  }

  @override
  String toString() {
    return "Dialog{id=$id $otherNickname}";
  }
}
