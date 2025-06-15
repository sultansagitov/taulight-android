import 'dart:convert';
import 'dart:typed_data';

import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform_service.dart';

class PlatformMessagesService {
  static final _instance = PlatformMessagesService._internal();
  static PlatformMessagesService get ins => _instance;
  PlatformMessagesService._internal();

  Future<int> loadMessages(TauChat chat, int i, int size) async {
    var result = await PlatformService.ins.method("load-messages", {
      "uuid": chat.client.uuid,
      "chat-id": chat.record.id,
      "index": i,
      "size": size,
    });

    if (result is ExceptionResult) {
      throw result.getCause(chat.client);
    }

    if (result is SuccessResult) {
      print("Loading messages: $chat ${result.obj}");
      var obj = result.obj;
      if (obj is Map) {
        var messages = obj["messages"];
        for (var json in messages) {
          var message = ChatMessageWrapperDTO.fromMap(chat.client, json);
          chat.addMessage(message);
        }
        return obj["count"];
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<Map<String, String>> sendMessage(
    TauChat chat,
    ChatMessageViewDTO message,
  ) async {
    var args = {
      "uuid": chat.client.uuid,
      "chat-id": chat.record.id,
      "content": message.text,
      "replied-to-messages": message.repliedToMessages,
      "file-id": message.files.map((f) => f.id).toList(),
    };
    Result result = isGroup(chat)
        ? await PlatformService.ins.method("group-send", args)
        : await PlatformService.ins.method("dialog-send", {
            ...args,
            "nickname": (chat.record as DialogDTO).otherNickname,
          });

    if (result is ExceptionResult) {
      throw result.getCause(chat.client);
    }

    if (result is SuccessResult) {
      return Map<String, String>.from(result.obj);
    }

    throw IncorrectFormatChannelException();
  }

  Future<Uint8List> downloadFile(Client client, String fileId) async {
    var result = await PlatformService.ins.chain(
      "MessageFileClientChain.download",
      client: client,
      params: [fileId],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(client);
      }
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      final map = Map<String, dynamic>.from(result.obj);
      final base64Str = map["avatarBase64"]!;
      return base64Decode(base64Str);
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> uploadFile(TauChat chat, String path, String filename) async {
    var result = await PlatformService.ins.chain(
      "MessageFileClientChain.upload",
      client: chat.client,
      params: [chat.record.id, path, filename],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(chat.client);
      }
      throw result.getCause(chat.client);
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is String) {
        return obj;
      }
    }

    throw IncorrectFormatChannelException();
  }
}
