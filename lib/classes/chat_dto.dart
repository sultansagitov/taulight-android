import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/client.dart';

abstract class ChatDTO {
  final String id;
  final ChatMessageWrapperDTO lastMessage;
  final String? avatarID;

  static ChatDTO fromMap(client, obj) {
    final map = Map<String, dynamic>.from(obj);

    var type = map["chat"]["type"];
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
    return GroupDTO(
      id: obj["chat"]["id"]!,
      lastMessage: ChatMessageWrapperDTO(
        ChatMessageViewDTO.fromMap(client, obj["chat"]['last-message']),
        obj["decrypted-last-message"],
      ),
      avatarID: obj["chat"]["avatar"],
      title: obj["chat"]["group-title"]!,
      owner: obj["chat"]["group-owner"]!,
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
    var otherNickname = obj["chat"]["dialog-other"]!;
    return DialogDTO(
      id: obj["chat"]["id"]!,
      lastMessage: ChatMessageWrapperDTO(
        ChatMessageViewDTO.fromMap(client, obj["chat"]['last-message']),
        obj["decrypted-last-message"],
      ),
      avatarID: obj["chat"]["avatar"],
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
