import 'dart:ui';

import 'package:collection/collection.dart' show ListExtensions;
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class TauChat {
  final Client client;
  final ChatDTO record;
  final List<ChatMessageViewDTO> messages;

  int? totalCount;
  List<ChatMessageViewDTO> get realMsg {
    return messages.where((m) => !m.text.startsWith("temp_")).toList();
  }

  TauChat(this.client, this.record) : messages = [record.lastMessage] {
    print("new TauChat");
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
    List<ChatMessageViewDTO> real = realMsg;
    bool needsMoreMessages = real.length < (offset + limit);
    bool hasMoreMessages = totalCount == null || real.length < totalCount!;

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
      chatID: record.id,
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

  Future<List<Member>> getMembers() => JavaService.instance.getMembers(this);

  Future<String> addMember(String nickname) async {
    return await JavaService.instance.addMember(client, this, nickname);
  }

  static Future<void> loadAll({
    VoidCallback? callback,
    void Function(Client, Object)? onError,
  }) async {
    for (Client client in JavaService.instance.clients.values) {
      try {
        if (!client.connected || client.user == null) continue;

        User user = client.user!;

        if (!user.authorized) {
          ServerRecord? server =
              await StorageService.instance.getClient(client.uuid);

          if (server == null) {
            client.user = null;
            continue;
          }

          UserRecord? record = server.user;

          if (record == null) {
            client.user = null;
            continue;
          }

          await client.authByToken(record.token);
          callback?.call();
        }

        if (!client.authorized) continue;

        await client.loadChats();
      } catch (e) {
        print(e);
        onError?.call(client, e);
      }
    }
  }

  @override
  String toString() =>
      "TauChat{${record.id} ${realMsg.length}/$totalCount messages}";
}
