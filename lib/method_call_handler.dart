import 'package:flutter/services.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/classes/client.dart';

class MethodCallHandler {
  final Map<String, Future<void> Function(MethodCall)> handlers = {};

  MethodCallHandler() {
    handlers["onmessage"] = _onMessage;
    handlers["disconnect"] = _disconnect;
  }

  Future<void> handle(MethodCall call) async {
    print("Handling ${call.method} from java channel");
    await handlers[call.method]!(call);
  }

  static Future<void> _onMessage(call) async {
    String clientUUID = call.arguments["uuid"];
    Client? client = JavaService.instance.getClientByUUID(clientUUID);

    if (client == null) {
      throw ClientNotFoundException(clientUUID);
    }

    ChatMessageViewDTO message = ChatMessageViewDTO.fromMap(client, call.arguments["message"]);
    TauChat chat = await client.getOrLoadChatByID(message.chatID);
    if (!message.isMe) chat.addMessage(message);
  }

  static Future<void> _disconnect(call) async {
    String clientUUID = call.arguments["uuid"];
    Client? client = JavaService.instance.getClientByUUID(clientUUID);

    if (client == null) {
      throw ClientNotFoundException(clientUUID);
    }

    client.connected = false;
  }
}
