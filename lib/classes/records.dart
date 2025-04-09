import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';

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

abstract class ChatRecord {
  final String id;

  static ChatRecord fromMap(obj) {
    var map = Map<String, dynamic>.from(obj);
    var type = map["type"];
    switch (type) {
      case "cn":
        return ChannelRecord.fromMap(map);
      case "dl":
        return DialogRecord.fromMap(map);
      default:
        throw ErrorDescription('Unexpected type "$type", - "cn", "dl"');
    }
  }

  ChatRecord({required this.id});

  String getTitle();
}

class ChannelRecord extends ChatRecord {
  final String title;
  final String owner;

  ChannelRecord({required super.id, required this.title, required this.owner});

  factory ChannelRecord.fromMap(Map<String, dynamic> obj) {
    return ChannelRecord(
      id: obj["id"]!,
      title: obj["channel-title"]!,
      owner: obj["channel-owner"]!,
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

class DialogRecord extends ChatRecord {
  final String otherNickname;

  DialogRecord({required super.id, required this.otherNickname});

  factory DialogRecord.fromMap(Map<String, dynamic> obj) {
    return DialogRecord(id: obj["id"]!, otherNickname: obj["dialog-other"]!);
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

class Message {
  String id;
  final String chatID;
  final String nickname;
  final String text;
  final bool isMe;
  final DateTime dateTime;
  final bool sys;
  final List<String>? replies;

  Message({
    required this.id,
    required this.chatID,
    required this.nickname,
    required this.text,
    required this.isMe,
    required this.dateTime,
    required this.sys,
    required this.replies,
  });

  static Message fromMap(Client client, json) {
    var map = Map<String, dynamic>.from(json as Map);

    String messageID = map["id"]!;
    DateTime dateTime = DateTime.parse(map["creation-date"]!).toLocal();

    var message = map["message"]!;

    String chatID = message["chat-id"]!;
    String nickname = message["nickname"]!;
    String content = message["content"]!;
    bool sys = message["sys"];
    var replies = message["replies"] != null
        ? List<String>.from(message["replies"])
        : null;

    return Message(
      id: messageID,
      chatID: chatID,
      nickname: nickname,
      isMe: client.user?.nickname == nickname,
      text: content,
      dateTime: dateTime,
      sys: sys,
      replies: replies,
    );
  }

  @override
  String toString() {
    return "Message{chat=$chatID, member=$nickname, content=$text}";
  }
}

class TauCode {
  final String title;
  final String nickname;
  final String sender;
  final DateTime creation;
  final DateTime? activation;
  final DateTime expires;

  bool get isExpired => DateTime.now().isAfter(expires);

  TauCode({
    required this.title,
    required this.nickname,
    required this.sender,
    required this.creation,
    required this.expires,
    this.activation,
  });

  factory TauCode.fromMap(Map<String, dynamic> map) {
    var activationString = map["activation-date"];
    DateTime? activation;

    if (activationString != null) {
      activation = DateTime.parse(activationString as String);
    }

    return TauCode(
      title: map["title"] as String,
      nickname: map["nickname"] as String,
      sender: map["sender-nickname"] as String,
      creation: DateTime.parse(map["creation-date"] as String),
      expires: DateTime.parse(map["expires-date"] as String),
      activation: activation,
    );
  }
}
