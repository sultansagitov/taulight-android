import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/avatar_service.dart';

enum Status {
  online,
  offline,
  hidden;

  factory Status.fromString(String s) {
    for (Status status in Status.values) {
      if (status.name == s.toLowerCase()) {
        return status;
      }
    }

    return Status.hidden;
  }
}

abstract class ChatDTO {
  final String id;
  final ChatMessageWrapperDTO lastMessage;

  static ChatDTO fromMap(client, obj) {
    final map = Map<String, dynamic>.from(obj);

    bool? hasAvatar = map["chat"]['has-avatar'];
    if (hasAvatar != null) {
      final id = obj["chat"]["id"]!;
      if (hasAvatar) {
        print("remove no avatar $id");
        AvatarService.ins.removeNoAvatar(client, id);
      } else {
        print("set no avatar $id");
        AvatarService.ins.setNoAvatar(client, id);
      }
    }

    var type = map["chat"]["type"];
    switch (type) {
      case "cn":
        return ChannelDTO.fromMap(client, map);
      case "dl":
        return DialogDTO.fromMap(client, map);
      default:
        throw ErrorDescription('Unexpected type "$type", - "cn", "dl"');
    }
  }

  ChatDTO({required this.id, required this.lastMessage});

  String getTitle();
}

class ChannelDTO extends ChatDTO {
  final String title;
  final String owner;

  ChannelDTO({
    required super.id,
    required super.lastMessage,
    required this.title,
    required this.owner,
  });

  factory ChannelDTO.fromMap(Client client, Map<String, dynamic> obj) {
    return ChannelDTO(
      id: obj["chat"]["id"]!,
      lastMessage: ChatMessageWrapperDTO(
        ChatMessageViewDTO.fromMap(client, obj["chat"]['last-message']),
        obj["decrypted-last-message"],
      ),
      title: obj["chat"]["channel-title"]!,
      owner: obj["chat"]["channel-owner"]!,
    );
  }

  @override
  String getTitle() {
    return title;
  }

  @override
  String toString() {
    return "Channel{id=$id title=$title}";
  }
}

class DialogDTO extends ChatDTO {
  final String otherNickname;

  DialogDTO({
    required super.id,
    required super.lastMessage,
    required this.otherNickname,
  });

  factory DialogDTO.fromMap(Client client, Map<String, dynamic> obj) {
    return DialogDTO(
      id: obj["chat"]["id"]!,
      lastMessage: ChatMessageWrapperDTO(
        ChatMessageViewDTO.fromMap(client, obj["chat"]['last-message']),
        obj["decrypted-last-message"],
      ),
      otherNickname: obj["chat"]["dialog-other"]!,
    );
  }

  @override
  String getTitle() {
    return otherNickname;
  }

  @override
  String toString() {
    return "Channel{id=$id $otherNickname}";
  }
}

class Member {
  String nickname;
  Status status;

  Member(this.nickname, this.status);

  factory Member.fromMap(map) {
    var m = Map<String, String>.from(map);
    return Member(m["nickname"]!, Status.fromString(m["status"]!));
  }
}

class ChatMessageViewDTO {
  String id;
  final String chatID;
  final String nickname;
  final String text;
  final bool isMe;
  final DateTime dateTime;
  final bool sys;
  final List<String> repliedToMessages;
  final Map<String, List<String>> reactions;

  ChatMessageViewDTO({
    required this.id,
    required this.chatID,
    required this.nickname,
    required this.text,
    required this.isMe,
    required this.dateTime,
    required this.sys,
    required this.repliedToMessages,
    required this.reactions,
  });

  static ChatMessageViewDTO fromMap(Client client, json) {
    var map = Map<String, dynamic>.from(json as Map);

    String messageID = map["id"]!;
    DateTime dateTime = DateTime.parse(map["creation-date"]!).toLocal();
    var reactions = <String, List<String>>{};

    var entries = map["reactions"].entries;
    for (var entry in entries) {
      var mapped = entry.value.map<String>((n) => n.toString());
      reactions[entry.key] = mapped.toList();
    }

    var message = map["message"]!;

    String chatID = message["chat-id"]!;
    String nickname = message["nickname"]!;
    String content = message["content"]!;
    bool sys = message["sys"];
    var repliedToMessages = message["repliedToMessages"] != null
        ? List<String>.from(message["repliedToMessages"])
        : <String>[];

    return ChatMessageViewDTO(
      id: messageID,
      chatID: chatID,
      nickname: nickname,
      isMe: client.user?.nickname == nickname,
      text: content,
      dateTime: dateTime,
      sys: sys,
      repliedToMessages: repliedToMessages,
      reactions: reactions,
    );
  }

  @override
  String toString() {
    return "Message{chat=$chatID, member=$nickname, content=$text}";
  }
}

class CodeDTO {
  final String title;
  final String nickname;
  final String sender;
  final DateTime creation;
  final DateTime? activation;
  final DateTime expires;

  bool get isExpired => DateTime.now().isAfter(expires);

  CodeDTO({
    required this.title,
    required this.nickname,
    required this.sender,
    required this.creation,
    required this.expires,
    this.activation,
  });

  factory CodeDTO.fromMap(Map<String, dynamic> map) {
    var activationString = map["activation-date"];
    DateTime? activation;

    if (activationString != null) {
      activation = DateTime.parse(activationString as String);
    }

    return CodeDTO(
      title: map["title"] as String,
      nickname: map["receiver-nickname"] as String,
      sender: map["sender-nickname"] as String,
      creation: DateTime.parse(map["creation-date"] as String),
      expires: DateTime.parse(map["expires-date"] as String),
      activation: activation,
    );
  }
}
