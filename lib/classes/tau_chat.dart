import 'dart:ui';

import 'package:collection/collection.dart' show ListExtensions;
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class TauChat {
  final String id;
  final Client client;
  ChatDTO? record;
  int? totalCount;

  final List<ChatMessageViewDTO> messages = [];
  List<ChatMessageViewDTO> get realMsg {
    return messages.where((m) => !m.text.startsWith("temp_")).toList();
  }

  TauChat(this.client, this.id);
  factory TauChat.fromRecord(Client client, ChatDTO record) {
    return TauChat(client, record.id)..record = record;
  }

  void addMessage(ChatMessageViewDTO message) {
    if (!messages.any((m) => m.id == message.id)) {
      int index = messages.lowerBound(
        message,
        (a, b) => a.dateTime.compareTo(b.dateTime),
      );
      totalCount = totalCount != null ? totalCount! + 1 : null;
      messages.insert(index, message);
    }
  }

  Future<void> loadMessages(int offset, int limit) async {
    bool needsMoreMessages = realMsg.length < (offset + limit);
    bool hasMoreMessages = totalCount == null || realMsg.length < totalCount!;

    if (needsMoreMessages && hasMoreMessages) {
      totalCount = await JavaService.instance.loadMessages(this, offset, limit);
    }
  }

  Future<void> sendMessage(
    String text,
    List<String> repliedToMessages,
    VoidCallback callback,
  ) async {
    var tempUuid = "temp_${Uuid().v4()}";

    var message = ChatMessageViewDTO(
      id: tempUuid,
      chatID: id,
      nickname: client.user!.nickname,
      text: text,
      isMe: true,
      dateTime: DateTime.now(),
      sys: false,
      repliedToMessages: repliedToMessages,
      reactions: {},
    );

    addMessage(message);
    callback();

    var messageUuid = await client.sendMessage(this, message);
    message.id = messageUuid;
    callback();
  }

  String getTitle() => record?.getTitle() ?? "Unknown";

  @override
  String toString() => "TauChat{$id ${realMsg.length}/$totalCount messages}";

  Future<List<Member>> getMembers() => JavaService.instance.getMembers(this);

  Future<String> addMember(String nickname) async {
    return await JavaService.instance.addMember(client, this, nickname);
  }

  static Future<void> loadAll({
    VoidCallback? callback,
    void Function(Client, Object)? onError,
  }) async {
    Map<String, ServerRecord>? map;

    for (Client client in JavaService.instance.clients.values) {
      try {
        User? user = client.user;
        if (user != null) {
          if (!client.connected) continue;

          if (!user.authorized) {
            map ??= await StorageService.getClients();

            ServerRecord? serverRecord = map[client.uuid];

            if (serverRecord == null) {
              client.user = null;
              continue;
            }

            UserRecord? user = serverRecord.user;

            if (user == null) {
              client.user = null;
              continue;
            }

            await client.authByToken(user.token);
          }

          await client.loadChats();
          for (var chat in client.chats.values) {
            await chat.loadMessages(0, 2);
            if (callback != null) callback();
          }
        }
      } catch (e) {
        if (onError != null) onError(client, e);
      }
    }
  }
}
