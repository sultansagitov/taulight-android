import 'dart:convert';
import 'dart:typed_data';

import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/uuid.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform/platform_service.dart';

class PlatformMessagesService {
  static final _instance = PlatformMessagesService._internal();
  static PlatformMessagesService get ins => _instance;
  PlatformMessagesService._internal();

  Future<int> loadMessages(TauChat chat, int i, int size) async {
    final result = await PlatformService.ins.method("load-messages", {
      "uuid": chat.client.uuid.toString(),
      "chat-id": chat.record.id.toString(),
      "index": i,
      "size": size,
    });

    if (result is ExceptionResult) {
      throw result.getCause(chat.client);
    }

    if (result is SuccessResult) {
      print("Loading messages: $chat ${result.obj}");
      final obj = result.obj;
      if (obj is Map) {
        final messages = obj["messages"];
        for (final json in messages) {
          final message = ChatMessageWrapperDTO.fromMap(chat.client, json);
          chat.addMessage(message);
        }
        return obj["count"]! as int;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<Map<String, String>> sendMessage(
    TauChat chat,
    ChatMessageViewDTO message,
  ) async {
    final args = {
      "uuid": chat.client.uuid.toString(),
      "chat-id": chat.record.id.toString(),
      "content": message.text,
      "replied-to-messages":
          message.repliedToMessages.map((u) => u.toString()).toList(),
      "file-id": message.files.map((f) => f.id!.toString()).toList(),
    };
    Result result = await PlatformService.ins.method("send", args);

    if (result is ExceptionResult) {
      throw result.getCause(chat.client);
    }

    if (result is SuccessResult) {
      return Map<String, String>.from(result.obj);
    }

    throw IncorrectFormatChannelException();
  }

  Future<Uint8List> downloadFile(Client client, UUID fileId) async {
    final result = await PlatformService.ins.chain(
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
      final String base64Str = map["avatarBase64"]!;
      return base64Decode(base64Str);
    }

    throw IncorrectFormatChannelException();
  }

  Future<UUID> uploadFile(TauChat chat, String path, String filename) async {
    final result = await PlatformService.ins.chain(
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
      final obj = result.obj;
      if (obj is String) {
        return UUID.fromString(obj);
      }
    }

    throw IncorrectFormatChannelException();
  }
}
