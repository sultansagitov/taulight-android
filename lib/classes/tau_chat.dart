import 'dart:ui';

import 'package:collection/collection.dart' show ListExtensions;
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/role_dto.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/classes/uuid.dart';
import 'package:taulight/services/client.dart';
import 'package:taulight/services/platform/agent.dart';
import 'package:taulight/services/platform/messages.dart';
import 'package:taulight/services/storage.dart';

import 'chat_message_wrapper_dto.dart';

class TauChat {
  final Client client;
  final ChatDTO record;
  final List<ChatMessageWrapperDTO> messages;
  final List<RoleDTO> roles = [];
  UUID? avatarID;

  int? totalCount;
  List<ChatMessageWrapperDTO> get realMsg {
    return messages.where((m) => m.isLoading).toList();
  }

  TauChat(this.client, this.record) : messages = [record.lastMessage];

  void addMessage(ChatMessageWrapperDTO message) {
    if (!messages.any((m) => m.view.id == message.view.id)) {
      int index = messages.lowerBound(
        message,
        (a, b) => a.view.dateTime.compareTo(b.view.dateTime),
      );
      totalCount = totalCount != null ? totalCount! + 1 : null;
      messages.insert(index, message);
    }
  }

  Future<void> loadMessages(int offset, int limit) async {
    List<ChatMessageWrapperDTO> real = realMsg;
    bool needsMoreMessages = real.length < (offset + limit);
    bool hasMoreMessages = totalCount == null || real.length < totalCount!;

    if (needsMoreMessages && hasMoreMessages) {
      totalCount = await PlatformMessagesService.ins.loadMessages(
        this,
        offset,
        limit,
      );
    }
  }

  Future<void> sendMessage(
    String text,
    List<UUID> repliedToMessages,
    List<NamedFileDTO> files,
    VoidCallback callback,
  ) async {
    final dateTime = DateTime.now();
    final message = ChatMessageViewDTO.loading(
      chatID: record.id,
      keyID: null,
      nickname: client.user!.nickname,
      text: text,
      creationDate: dateTime,
      sentDate: dateTime,
      sys: false,
      repliedToMessages: repliedToMessages,
      reactions: {},
      files: files,
    );

    final wrapper = ChatMessageWrapperDTO.loading(message, text);

    addMessage(wrapper);
    callback();

    final map = await PlatformMessagesService.ins.sendMessage(this, message);
    wrapper.isLoading = false;
    message.id = UUID.fromString(map["message"]!);
    message.keyID = UUID.fromNullableString(map["key"]);
    callback();
  }

  static Future<void> loadAll({
    VoidCallback? callback,
    void Function(Client, dynamic)? onError,
  }) async {
    for (Client client in ClientService.ins.clientsList) {
      try {
        if (!client.connected || client.user == null) continue;

        User user = client.user!;

        if (!user.authorized) {
          ServerRecord? server =
              await StorageService.ins.getClient(client.uuid);

          if (server == null) {
            client.user = null;
            continue;
          }

          UserRecord? record = server.user;

          if (record == null) {
            client.user = null;
            continue;
          }

          await PlatformAgentService.ins.authByToken(client, record.token);
          callback?.call();
        }

        if (!client.authorized) continue;

        await client.loadChats();
      } catch (e, stackTrace) {
        print(e);
        print(stackTrace);
        onError?.call(client, e);
      }
    }
  }

  @override
  String toString() =>
      "TauChat{${record.id} ${realMsg.length}/$totalCount messages}";
}
