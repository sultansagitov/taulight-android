import 'package:taulight/classes/client.dart';

class ChatMessageViewDTO {
  String id;
  String? keyID;
  final String chatID;
  final String nickname;
  final String text;
  final bool isMe;
  final DateTime dateTime;
  final bool sys;
  final List<String> repliedToMessages;
  final Map<String, List<String>> reactions;
  final List<NamedFileDTO> files;

  ChatMessageViewDTO({
    required this.id,
    required this.chatID,
    required this.keyID,
    required this.nickname,
    required this.text,
    required this.isMe,
    required this.dateTime,
    required this.sys,
    required this.repliedToMessages,
    required this.reactions,
    required this.files,
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

    List<NamedFileDTO> files = map["files"] != null
        ? (map["files"] as List).map((m) => NamedFileDTO.fromMap(m)).toList()
        : <NamedFileDTO>[];

    var message = map["message"]!;
    String chatID = message["chat-id"]!;
    String? keyId = message["key-id"];
    String nickname = message["nickname"]!;
    String content = message["content"]!;
    bool sys = message["sys"];
    var repliedToMessages = message["replied-to-messages"] != null
        ? List<String>.from(message["replied-to-messages"])
        : <String>[];

    return ChatMessageViewDTO(
      id: messageID,
      chatID: chatID,
      keyID: keyId,
      nickname: nickname,
      isMe: client.user?.nickname == nickname,
      text: content,
      dateTime: dateTime,
      sys: sys,
      repliedToMessages: repliedToMessages,
      files: files,
      reactions: reactions,
    );
  }

  @override
  String toString() {
    return "Message{chat=$chatID, member=$nickname, content=$text}";
  }
}

class NamedFileDTO {
  String? id;
  final String contentType;
  final String filename;

  NamedFileDTO(this.id, this.contentType, this.filename);

  factory NamedFileDTO.fromMap(map) => NamedFileDTO(
      map["id"], map["content-type"], map["filename"] ?? map["id"]);
}
