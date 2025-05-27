import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/services/client_service.dart';
import 'package:taulight/exceptions.dart';

class MethodCallHandler {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  final Map<String, Future Function(MethodCall)> handlers = {
    "onmessage": _onMessage,
    "disconnect": _disconnect,
    "get-public-key": _getPublicKey,
    "save-key": _saveKey,
    "save-personal-key": _savePersonalKey,
    "save-encryptor": _saveEncryptor,
    "save-dek": _saveDEK,
    "load-personal-key": _loadPersonalKey,
    "load-encryptor": _loadEncryptor,
    "load-dek": _loadDEK,
    "load-dek-by-id": _loadDEKByID,
  };

  Future handle(MethodCall call) async {
    print("Handling ${call.method} from Java channel");
    return await handlers[call.method]?.call(call);
  }

  static Future<void> _onMessage(MethodCall call) async {
    final clientUUID = call.arguments["uuid"];
    final messageMap = call.arguments["message"];
    final decrypted = call.arguments["decrypted"];
    final yourSession = call.arguments["your-session"];

    Client? client = ClientService.ins.get(clientUUID);
    if (client == null) throw ClientNotFoundException(clientUUID);

    final view = ChatMessageViewDTO.fromMap(client, messageMap);
    final wrapper = ChatMessageWrapperDTO(view, decrypted);
    final chat = await client.getOrSaveChatByID(view.chatID);
    if (!yourSession) chat.addMessage(wrapper);
  }

  static Future<void> _disconnect(MethodCall call) async {
    String clientUUID = call.arguments["uuid"];
    Client? client = ClientService.ins.get(clientUUID);
    if (client == null) throw ClientNotFoundException(clientUUID);

    client.connected = false;
  }

  static Future<Map<String, String>> _getPublicKey(MethodCall call) async {
    String uuid = call.arguments["uuid"];
    String endpoint = call.arguments["endpoint"];

    final key = await _secureStorage.read(key: "public-key:$uuid:$endpoint");
    final priv = await _secureStorage.read(key: "private-key:$uuid:$endpoint");
    final enc = await _secureStorage.read(key: "encryption:$uuid:$endpoint");

    if (key == null || priv == null || enc == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "Public key not found for endpoint $endpoint",
      );
    }

    return {
      "uuid": uuid,
      "endpoint": endpoint,
      "public-key": key,
      "private-key": priv,
      "encryption": enc,
    };
  }

  static Future<void> _saveKey(MethodCall call) async {
    String uuid = call.arguments["uuid"];
    String endpoint = call.arguments["endpoint"];
    String encryption = call.arguments["encryption"];
    String publicKey = call.arguments["public-key"];
    String privateKey = call.arguments["private-key"];

    await _secureStorage.write(
      key: "encryption:$uuid:$endpoint",
      value: encryption,
    );
    await _secureStorage.write(
      key: "public-key:$uuid:$endpoint",
      value: publicKey,
    );
    await _secureStorage.write(
      key: "private-key:$uuid:$endpoint",
      value: privateKey,
    );
  }

  static Future<void> _savePersonalKey(MethodCall call) async {
    String uuid = call.arguments["uuid"];
    String keyID = call.arguments["key-id"];
    String encryption = call.arguments["encryption"];

    await _secureStorage.write(
        key: "personal-encryption:$uuid:$keyID", value: encryption);

    if (call.arguments.containsKey("sym-key")) {
      await _secureStorage.write(
        key: "personal-sym-key:$uuid:$keyID",
        value: call.arguments["sym-key"],
      );
    }
    if (call.arguments.containsKey("public-key")) {
      await _secureStorage.write(
        key: "personal-public-key:$uuid:$keyID",
        value: call.arguments["public-key"],
      );
      await _secureStorage.write(
        key: "personal-private-key:$uuid:$keyID",
        value: call.arguments["private-key"],
      );
    }
  }

  static Future<void> _saveEncryptor(MethodCall call) async {
    String uuid = call.arguments["uuid"];
    String nickname = call.arguments["nickname"];
    String keyID = call.arguments["key-id"];
    String encryption = call.arguments["encryption"];

    await _secureStorage.write(
      key: "encryptor-id:$uuid:$nickname",
      value: keyID,
    );
    await _secureStorage.write(
      key: "encryptor-encryption:$uuid:$nickname",
      value: encryption,
    );

    if (call.arguments.containsKey("sym-key")) {
      await _secureStorage.write(
        key: "encryptor-sym-key:$uuid:$nickname",
        value: call.arguments["sym-key"],
      );
    }
    if (call.arguments.containsKey("public-key")) {
      await _secureStorage.write(
        key: "encryptor-public-key:$uuid:$nickname",
        value: call.arguments["public-key"],
      );
      await _secureStorage.write(
        key: "encryptor-private-key:$uuid:$nickname",
        value: call.arguments["private-key"],
      );
    }
  }

  static Future<void> _saveDEK(MethodCall call) async {
    String uuid = call.arguments["uuid"];
    String nickname = call.arguments["nickname"];
    String keyID = call.arguments["key-id"];
    String encryption = call.arguments["encryption"];

    await _secureStorage.write(key: "dek-id:$uuid:$nickname", value: keyID);
    await _secureStorage.write(
      key: "dek-encryption:$uuid:$nickname",
      value: encryption,
    );

    if (call.arguments.containsKey("sym-key")) {
      await _secureStorage.write(
        key: "dek-sym-key:$uuid:$nickname",
        value: call.arguments["sym-key"],
      );
    }
    if (call.arguments.containsKey("public-key")) {
      await _secureStorage.write(
        key: "dek-public-key:$uuid:$nickname",
        value: call.arguments["public-key"],
      );
      await _secureStorage.write(
        key: "dek-private-key:$uuid:$nickname",
        value: call.arguments["private-key"],
      );
    }
  }

  static Future<Map<String, String?>> _loadPersonalKey(MethodCall call) async {
    String uuid = call.arguments["uuid"];
    String keyID = call.arguments["key-id"];

    final encryption =
        await _secureStorage.read(key: "personal-encryption:$uuid:$keyID");
    if (encryption == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "Personal key not found for ID $keyID",
      );
    }

    final result = <String, String?>{"encryption": encryption};

    if (await _secureStorage.containsKey(
        key: "personal-sym-key:$uuid:$keyID")) {
      result["sym-key"] = await _secureStorage.read(
        key: "personal-sym-key:$uuid:$keyID",
      );
    } else {
      result["public-key"] = await _secureStorage.read(
        key: "personal-public-key:$uuid:$keyID",
      );
      result["private-key"] = await _secureStorage.read(
        key: "personal-private-key:$uuid:$keyID",
      );
    }

    return result;
  }

  static Future<Map<String, String?>> _loadEncryptor(MethodCall call) async {
    String uuid = call.arguments["uuid"];
    String nickname = call.arguments["nickname"];

    final keyID =
        await _secureStorage.read(key: "encryptor-id:$uuid:$nickname");
    final encryption =
        await _secureStorage.read(key: "encryptor-encryption:$uuid:$nickname");
    if (keyID == null || encryption == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "Encryptor not found for nickname $nickname",
      );
    }

    final result = <String, String?>{"key-id": keyID, "encryption": encryption};

    if (await _secureStorage.containsKey(
        key: "encryptor-sym-key:$uuid:$nickname")) {
      result["sym-key"] =
          await _secureStorage.read(key: "encryptor-sym-key:$uuid:$nickname");
    } else {
      result["public-key"] = await _secureStorage.read(
        key: "encryptor-public-key:$uuid:$nickname",
      );
      result["private-key"] = await _secureStorage.read(
        key: "encryptor-private-key:$uuid:$nickname",
      );
    }

    return result;
  }

  static Future<Map<String, String?>> _loadDEK(MethodCall call) async {
    String uuid = call.arguments["uuid"];
    String nickname = call.arguments["nickname"];

    final keyID = await _secureStorage.read(key: "dek-id:$uuid:$nickname");
    final encryption =
        await _secureStorage.read(key: "dek-encryption:$uuid:$nickname");
    if (keyID == null || encryption == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "DEK not found for nickname $nickname",
      );
    }

    final result = <String, String?>{"key-id": keyID, "encryption": encryption};

    if (await _secureStorage.containsKey(key: "dek-sym-key:$uuid:$nickname")) {
      result["sym-key"] =
          await _secureStorage.read(key: "dek-sym-key:$uuid:$nickname");
    } else {
      result["public-key"] =
          await _secureStorage.read(key: "dek-public-key:$uuid:$nickname");
      result["private-key"] =
          await _secureStorage.read(key: "dek-private-key:$uuid:$nickname");
    }

    return result;
  }

  static Future<Map<String, String?>> _loadDEKByID(MethodCall call) async {
    String uuid = call.arguments["uuid"];
    String keyID = call.arguments["key-id"];

    final encryption =
        await _secureStorage.read(key: "dek-encryption:$uuid:$keyID");
    if (encryption == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "DEK not found for ID $keyID",
      );
    }

    final result = <String, String?>{"encryption": encryption};

    if (await _secureStorage.containsKey(key: "dek-sym-key:$uuid:$keyID")) {
      result["sym-key"] =
          await _secureStorage.read(key: "dek-sym-key:$uuid:$keyID");
    } else {
      result["public-key"] = await _secureStorage.read(
        key: "dek-public-key:$uuid:$keyID",
      );
      result["private-key"] = await _secureStorage.read(
        key: "dek-private-key:$uuid:$keyID",
      );
    }

    return result;
  }
}
