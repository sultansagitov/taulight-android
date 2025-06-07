import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/client.dart';
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

    if (!yourSession) {
      final view = ChatMessageViewDTO.fromMap(client, messageMap);
      final wrapper = ChatMessageWrapperDTO(view, decrypted);
      final chat = await client.getOrSaveChatByID(view.chatID);
      chat.addMessage(wrapper);
    }
  }

  static Future<void> _disconnect(MethodCall call) async {
    String clientUUID = call.arguments["uuid"];
    Client? client = ClientService.ins.get(clientUUID);
    if (client == null) throw ClientNotFoundException(clientUUID);

    client.connected = false;
  }

  static Future<Map<String, String>> _getPublicKey(MethodCall call) async {
    String endpoint = call.arguments["endpoint"];

    final key = await _secureStorage.read(key: "public-key:$endpoint");
    final priv = await _secureStorage.read(key: "private-key:$endpoint");
    final enc = await _secureStorage.read(key: "encryption:$endpoint");

    if (key == null || priv == null || enc == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "Public key not found for endpoint $endpoint",
      );
    }

    return {
      "endpoint": endpoint,
      "public-key": key,
      "private-key": priv,
      "encryption": enc,
    };
  }

  static Future<void> _saveKey(MethodCall call) async {
    String endpoint = call.arguments["endpoint"];
    String encryption = call.arguments["encryption"];
    String publicKey = call.arguments["public-key"];
    String privateKey = call.arguments["private-key"];

    await _secureStorage.write(
      key: "encryption:$endpoint",
      value: encryption,
    );
    await _secureStorage.write(
      key: "public-key:$endpoint",
      value: publicKey,
    );
    await _secureStorage.write(
      key: "private-key:$endpoint",
      value: privateKey,
    );
  }

  static Future<void> _savePersonalKey(MethodCall call) async {
    String keyID = call.arguments["key-id"];
    String encryption = call.arguments["encryption"];

    await _secureStorage.write(
        key: "personal-encryption:$keyID", value: encryption);

    if (call.arguments.containsKey("sym-key")) {
      await _secureStorage.write(
        key: "personal-sym-key:$keyID",
        value: call.arguments["sym-key"],
      );
    }
    if (call.arguments.containsKey("public-key")) {
      await _secureStorage.write(
        key: "personal-public-key:$keyID",
        value: call.arguments["public-key"],
      );
      await _secureStorage.write(
        key: "personal-private-key:$keyID",
        value: call.arguments["private-key"],
      );
    }
  }

  static Future<void> _saveEncryptor(MethodCall call) async {
    String nickname = call.arguments["nickname"];
    String keyID = call.arguments["key-id"];
    String encryption = call.arguments["encryption"];

    await _secureStorage.write(
      key: "encryptor-id:$nickname",
      value: keyID,
    );
    await _secureStorage.write(
      key: "encryptor-encryption:$nickname",
      value: encryption,
    );

    if (call.arguments.containsKey("sym-key")) {
      await _secureStorage.write(
        key: "encryptor-sym-key:$nickname",
        value: call.arguments["sym-key"],
      );
    }
    if (call.arguments.containsKey("public-key")) {
      await _secureStorage.write(
        key: "encryptor-public-key:$nickname",
        value: call.arguments["public-key"],
      );
      await _secureStorage.write(
        key: "encryptor-private-key:$nickname",
        value: call.arguments["private-key"],
      );
    }
  }

  static Future<void> _saveDEK(MethodCall call) async {
    String nickname = call.arguments["nickname"];
    String keyID = call.arguments["key-id"];
    String encryption = call.arguments["encryption"];

    await _secureStorage.write(key: "dek-id:$nickname", value: keyID);
    await _secureStorage.write(
        key: "dek-encryption:$nickname", value: encryption);

    await _secureStorage.write(key: "dek-encryption:$keyID", value: encryption);

    if (call.arguments.containsKey("sym-key")) {
      String symKey = call.arguments["sym-key"];
      await _secureStorage.write(
        key: "dek-sym-key:$nickname",
        value: symKey,
      );
      await _secureStorage.write(
        key: "dek-sym-key:$keyID",
        value: symKey,
      );
    }

    if (call.arguments.containsKey("public-key") &&
        call.arguments.containsKey("private-key")) {
      String publicKey = call.arguments["public-key"];
      String privateKey = call.arguments["private-key"];

      await _secureStorage.write(
        key: "dek-public-key:$nickname",
        value: publicKey,
      );
      await _secureStorage.write(
        key: "dek-private-key:$nickname",
        value: privateKey,
      );

      await _secureStorage.write(
        key: "dek-public-key:$keyID",
        value: publicKey,
      );
      await _secureStorage.write(
        key: "dek-private-key:$keyID",
        value: privateKey,
      );
    }
  }

  static Future<Map<String, String?>> _loadPersonalKey(MethodCall call) async {
    String keyID = call.arguments["key-id"];

    final encryption =
        await _secureStorage.read(key: "personal-encryption:$keyID");
    if (encryption == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "Personal key not found for ID $keyID",
      );
    }

    final result = <String, String?>{"encryption": encryption};

    if (await _secureStorage.containsKey(key: "personal-sym-key:$keyID")) {
      result["sym-key"] = await _secureStorage.read(
        key: "personal-sym-key:$keyID",
      );
    } else {
      result["public-key"] = await _secureStorage.read(
        key: "personal-public-key:$keyID",
      );
      result["private-key"] = await _secureStorage.read(
        key: "personal-private-key:$keyID",
      );
    }

    return result;
  }

  static Future<Map<String, String?>> _loadEncryptor(MethodCall call) async {
    String nickname = call.arguments["nickname"];

    final keyID = await _secureStorage.read(key: "encryptor-id:$nickname");
    final encryption =
        await _secureStorage.read(key: "encryptor-encryption:$nickname");
    if (keyID == null || encryption == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "Encryptor not found for nickname $nickname",
      );
    }

    final result = <String, String?>{"key-id": keyID, "encryption": encryption};

    if (await _secureStorage.containsKey(key: "encryptor-sym-key:$nickname")) {
      result["sym-key"] =
          await _secureStorage.read(key: "encryptor-sym-key:$nickname");
    } else {
      result["public-key"] = await _secureStorage.read(
        key: "encryptor-public-key:$nickname",
      );
      result["private-key"] = await _secureStorage.read(
        key: "encryptor-private-key:$nickname",
      );
    }

    return result;
  }

  static Future<Map<String, String?>> _loadDEK(MethodCall call) async {
    String nickname = call.arguments["nickname"];

    final keyID = await _secureStorage.read(key: "dek-id:$nickname");
    if (keyID == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "DEK ID not found for nickname $nickname",
      );
    }

    return _loadDEKByID(MethodCall("loadDEKByID", {
      "key-id": keyID,
    }));
  }

  static Future<Map<String, String?>> _loadDEKByID(MethodCall call) async {
    String keyID = call.arguments["key-id"];

    final encryption = await _secureStorage.read(key: "dek-encryption:$keyID");
    if (encryption == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "DEK not found for ID $keyID",
      );
    }

    final result = <String, String?>{
      "key-id": keyID,
      "encryption": encryption,
    };

    if (await _secureStorage.containsKey(key: "dek-sym-key:$keyID")) {
      result["sym-key"] = await _secureStorage.read(key: "dek-sym-key:$keyID");
    } else {
      result["public-key"] =
          await _secureStorage.read(key: "dek-public-key:$keyID");
      result["private-key"] =
          await _secureStorage.read(key: "dek-private-key:$keyID");
    }

    return result;
  }
}
