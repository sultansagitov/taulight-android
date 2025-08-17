import 'package:flutter/services.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/keys.dart';
import 'package:taulight/classes/sources.dart';
import 'package:taulight/classes/uuid.dart';
import 'package:taulight/services/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/key_storages.dart';

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
  final clientUUID = UUID.fromString(call.arguments["uuid"]);
  final messageMap = call.arguments["message"];
  final String? decrypted = call.arguments["decrypted"];
  final bool yourSession = call.arguments["your-session"];

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
  UUID clientUUID = UUID.fromString(call.arguments["uuid"]);
  Client? client = ClientService.ins.get(clientUUID);
  if (client == null) throw ClientNotFoundException(clientUUID);

  client.connected = false;
}

Future<void> _saveServerKey(MethodCall call) async {
  String address = call.arguments["address"]!;
  await KeyStorageService.ins.saveServerKey(
    ServerKey(
      address: address,
      encryption: call.arguments["encryption"]!,
      publicKey: call.arguments["public"]!,
      source: HubSource(address: address),
    ),
  );
}

Future<void> _savePersonalKey(MethodCall call) async {
  final args = call.arguments;
  String address = args["address"]!;
  await KeyStorageService.ins.savePersonalKey(
    address: address,
    nickname: args["nickname"]!,
    key: PersonalKey(
        encryption: args["encryption"]!,
        symKey: args["sym"],
        publicKey: args["public"],
        privateKey: args["private"],
        source: HubSource(address: address)),
  );
}

Future<void> _saveEncryptor(MethodCall call) async {
  String address = call.arguments["address"]!;
  await KeyStorageService.ins.saveEncryptor(
    address: address,
    nickname: call.arguments["nickname"]!,
    key: EncryptorKey(
      encryption: call.arguments["encryption"]!,
      symKey: call.arguments["sym"],
      publicKey: call.arguments["public"],
      source: HubSource(address: address),
    ),
  );
}

Future<void> _saveDEK(MethodCall call) async {
  String address = call.arguments["address"]!;
  await KeyStorageService.ins.saveDEK(
    address: address,
    nickname: call.arguments["nickname"]!,
    dek: DEK(
      keyId: UUID.fromString(call.arguments["key-id"]),
      encryption: call.arguments["encryption"]!,
      symKey: call.arguments["sym"],
      publicKey: call.arguments["public"],
      privateKey: call.arguments["private"],
      source: HubSource(address: address),
    ),
  );
}

Future<Map<String, dynamic>> _loadServerKey(MethodCall call) async {
  String address = call.arguments["address"]!;
  final serverKey = await KeyStorageService.ins.loadServerKey(address);
  return serverKey.toMap();
}

Future<Map<String, dynamic>> _loadPersonalKey(MethodCall call) async {
  final personalKey = await KeyStorageService.ins.loadPersonalKey(
    address: call.arguments["address"]!,
    nickname: call.arguments["nickname"]!,
  );
  return personalKey.toMap();
}

Future<Map<String, dynamic>> _loadEncryptor(MethodCall call) async {
  final encryptor = await KeyStorageService.ins.loadEncryptor(
    address: call.arguments["address"]!,
    nickname: call.arguments["nickname"]!,
  );
  return encryptor.toMap();
}

Future<Map<String, dynamic>> _loadDEK(MethodCall call) async {
  final dek = await KeyStorageService.ins.loadDEK(
    address: call.arguments["address"]!,
    nickname: call.arguments["nickname"]!,
  );
  return dek.toMap();
}

Future<Map<String, dynamic>> _loadDEKByID(MethodCall call) async {
  final UUID keyID = UUID.fromString(call.arguments["key-id"]!);
  final DEK dek = await KeyStorageService.ins.loadDEKByID(keyID);
  return dek.toMap();
}
