import 'package:flutter/services.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/client_service.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/key_storage_service.dart';

class MethodCallHandler {
  final Map<String, Future Function(MethodCall)> handlers = {
    "onmessage": _onMessage,
    "disconnect": _disconnect,

    "save-server-key": _saveServerKey,
    "save-personal-key": _savePersonalKey,
    "save-encryptor": _saveEncryptor,
    "save-dek": _saveDEK,

    "load-server-key": _loadServerKey,
    "load-personal-key": _loadPersonalKey,
    "load-encryptor": _loadEncryptor,
    "load-dek": _loadDEK,
    "load-dek-by-id": _loadDEKByID,
  };

  Future handle(MethodCall call) async {
    print("Handling ${call.method} from Platform channel");
    return await handlers[call.method]?.call(call);
  }
}

Future<void> _onMessage(MethodCall call) async {
  final clientUUID = call.arguments["uuid"];
  final messageMap = call.arguments["message"];
  final decrypted = call.arguments["decrypted"];
  final yourSession = call.arguments["your-session"];

  Client? client = ClientService.ins.get(clientUUID);
  if (client == null) throw ClientNotFoundException(clientUUID);

  if (!yourSession) {
    final view = ChatMessageViewDTO.fromMap(client, messageMap);
    final wrapper = ChatMessageWrapperDTO(view, decrypted);
    final chat = await client.getOrSaveChatByID(view.chatID);
    chat.addMessage(wrapper);
  }
}

Future<void> _disconnect(MethodCall call) async {
  String clientUUID = call.arguments["uuid"];
  Client? client = ClientService.ins.get(clientUUID);
  if (client == null) throw ClientNotFoundException(clientUUID);

  client.connected = false;
}

Future<void> _saveServerKey(MethodCall call) async {
  await KeyStorageService.ins.saveServerKey(
    address: call.arguments["address"],
    publicKey: call.arguments["public"],
    encryption: call.arguments["encryption"],
  );
}

Future<void> _savePersonalKey(MethodCall call) async {
  await KeyStorageService.ins.savePersonalKey(
    call.arguments["address"],
    call.arguments["key-id"],
    call.arguments["encryption"],
    symKey: call.arguments["sym-key"],
    publicKey: call.arguments["public"],
    privateKey: call.arguments["private"],
  );
}

Future<void> _saveEncryptor(MethodCall call) async {
  await KeyStorageService.ins.saveEncryptor(
    call.arguments["address"],
    call.arguments["nickname"],
    call.arguments["key-id"],
    call.arguments["encryption"],
    symKey: call.arguments["sym-key"],
    publicKey: call.arguments["public"],
  );
}

Future<void> _saveDEK(MethodCall call) async {
  await KeyStorageService.ins.saveDEK(
    call.arguments["address"],
    call.arguments["nickname"],
    call.arguments["key-id"],
    call.arguments["encryption"],
    symKey: call.arguments["sym-key"],
    publicKey: call.arguments["public"],
    privateKey: call.arguments["private"],
  );
}

Future<Map<String, String>> _loadServerKey(MethodCall call) async {
  String address = call.arguments["address"];
  return await KeyStorageService.ins.loadServerKey(address);
}

Future<Map<String, String>> _loadPersonalKey(MethodCall call) async {
  return await KeyStorageService.ins.loadPersonalKey(
    call.arguments["address"],
    call.arguments["key-id"],
  );
}

Future<Map<String, String>> _loadEncryptor(MethodCall call) async {
  return await KeyStorageService.ins.loadEncryptor(
    call.arguments["address"],
    call.arguments["nickname"],
  );
}

Future<Map<String, String>> _loadDEK(MethodCall call) async {
  return await KeyStorageService.ins.loadDEK(
    call.arguments["address"],
    call.arguments["nickname"],
  );
}

Future<Map<String, String>> _loadDEKByID(MethodCall call) async {
  return await KeyStorageService.ins.loadDEKByID(
    call.arguments["address"],
    call.arguments["key-id"],
  );
}
