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
    String? keyId = message["keyID"];
    String nickname = message["nickname"]!;
    String content = message["content"]!;
    bool sys = message["sys"];
    var repliedToMessages = message["repliedToMessages"] != null
        ? List<String>.from(message["repliedToMessages"])
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
      reactions: reactions,
    );
  }

  @override
  String toString() {
    return "Message{chat=$chatID, member=$nickname, content=$text}";
  }
}
