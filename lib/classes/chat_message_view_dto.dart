import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/nickname.dart';
import 'package:taulight/classes/uuid.dart';

class ChatMessageViewDTO {
  UUID id;
  UUID? keyID;
  final UUID chatID;
  final Nickname nickname;
  final String text;
  final bool isMe;
  final DateTime creationDate;
  final DateTime sentDate;
  final bool sys;
  final List<UUID> repliedToMessages;
  final Map<String, List<String>> reactions;
  final List<NamedFileDTO> files;

  ChatMessageViewDTO({
    required this.id,
    required this.chatID,
    required this.keyID,
    required this.nickname,
    required this.text,
    required this.isMe,
    required this.creationDate,
    required this.sentDate,
    required this.sys,
    required this.repliedToMessages,
    required this.reactions,
    required this.files,
  });

  factory ChatMessageViewDTO.loading({
    required UUID chatID,
    required keyID,
    required Nickname nickname,
    required String text,
    required DateTime creationDate,
    required DateTime sentDate,
    required bool sys,
    required List<UUID> repliedToMessages,
    required Map<String, List<String>> reactions,
    required List<NamedFileDTO> files,
  }) {
    return ChatMessageViewDTO(
      id: UUID.nil,
      chatID: chatID,
      keyID: keyID,
      nickname: nickname,
      text: text,
      isMe: true,
      creationDate: creationDate, // TODO get from hub
      sentDate: sentDate,
      sys: sys,
      repliedToMessages: repliedToMessages,
      reactions: reactions,
      files: files,
    );
  }

  factory ChatMessageViewDTO.fromMap(Client client, json) {
    final map = Map<String, dynamic>.from(json as Map);

    final messageID = UUID.fromString(map["id"]!);
    final creationDate = DateTime.parse(map["creation-date"]!).toLocal();
    final reactions = <String, List<String>>{};

    final entries = map["reactions"]!.entries;
    for (final MapEntry<String, dynamic> entry in entries) {
      final mapped = entry.value.map<String>((n) => n.toString());
      reactions[entry.key] = mapped.toList();
    }

    List<NamedFileDTO> files = map["files"] != null
        ? (map["files"] as List).map(NamedFileDTO.fromMap).toList()
        : <NamedFileDTO>[];

    final message = map["message"]!;
    final chatID = UUID.fromString(message["chat-id"]);
    final keyID = UUID.fromNullableString(message["key-id"]);
    final nickname = Nickname.checked(message["nickname"]);

    final sentDate = DateTime.parse(message["sent-datetime"]!).toLocal();

    final String content = message["content"]!;
    final bool sys = message["sys"]!;

    final r = message["replied-to-messages"];

    List<UUID> repliedToMessages = r != null
        ? List<String>.from(r).map(UUID.fromString).toList()
        : <UUID>[];

    return ChatMessageViewDTO(
      id: messageID,
      chatID: chatID,
      keyID: keyID,
      nickname: nickname,
      isMe: client.user?.nickname == nickname,
      text: content,
      creationDate: creationDate,
      sentDate: sentDate,
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
  UUID? id;
  final String contentType;
  final String filename;

  NamedFileDTO(this.id, this.contentType, this.filename);

  factory NamedFileDTO.fromMap(map) => NamedFileDTO(
        UUID.fromString(map["id"]),
        map["content-type"],
        map["filename"] ?? map["id"]!,
      );
}
