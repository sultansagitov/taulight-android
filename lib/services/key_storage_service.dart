import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyStorageService {
  static final KeyStorageService _instance = KeyStorageService._internal();
  static KeyStorageService get ins => _instance;
  KeyStorageService._internal();

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> saveKey({
    required String address,
    required String publicKey,
    required String encryption,
  }) async {
    final keyData = jsonEncode({
      "address": address,
      "public": publicKey,
      "encryption": encryption,
    });
    await _secureStorage.write(key: "key:$address", value: keyData);
  }

  Future<Map<String, String>> getPublicKey(String address) async {
    final keyData = await _secureStorage.read(key: "key:$address");
    if (keyData == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "Key not found for address $address",
      );
    }
    return jsonDecode(keyData);
  }

  Future<void> savePersonalKey(
    String keyID,
    String encryption, {
    String? symKey,
    String? publicKey,
    String? privateKey,
  }) async {
    final data = {
      "encryption": encryption,
      if (symKey != null) ...{
        "sym": symKey,
      } else ...{
        "public": publicKey,
        "private": privateKey,
      }
    };
    await _secureStorage.write(key: "personal:$keyID", value: jsonEncode(data));
  }

  Future<Map<String, String>> loadPersonalKey(String keyID) async {
    final data = await _secureStorage.read(key: "personal:$keyID");
    if (data == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "Key not found for ID $keyID",
      );
    }
    return jsonDecode(data);
  }

  Future<void> saveEncryptor(
    String nickname,
    String keyID,
    String encryption, {
    String? symKey,
    String? publicKey,
  }) async {
    final data = {
      "key-id": keyID,
      "encryption": encryption,
      if (symKey != null) ...{
        "sym": symKey,
      } else ...{
        "public": publicKey,
      }
    };
    await _secureStorage.write(
      key: "encryptor:$nickname",
      value: jsonEncode(data),
    );
  }

  Future<Map<String, String>> loadEncryptor(String nickname) async {
    final data = await _secureStorage.read(key: "encryptor:$nickname");
    if (data == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "Encryptor not found",
      );
    }
    return jsonDecode(data);
  }

  Future<void> saveDEK(
    String nickname,
    String keyID,
    String encryption, {
    String? symKey,
    String? publicKey,
    String? privateKey,
  }) async {
    final data = {
      "key-id": keyID,
      "encryption": encryption,
      if (symKey != null) ...{
        "sym": symKey,
      } else ...{
        "public": publicKey,
        "private": privateKey,
      }
    };
    await _secureStorage.write(key: "dek:$nickname", value: jsonEncode(data));
    await _secureStorage.write(key: "dek:$keyID", value: jsonEncode(data));
  }

  Future<Map<String, String>> loadDEK(String nickname) async {
    final data = await _secureStorage.read(key: "dek:$nickname");
    if (data == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "DEK not found for nickname $nickname",
      );
    }
    return jsonDecode(data);
  }

  Future<Map<String, String>> loadDEKByID(String keyID) async {
    final data = await _secureStorage.read(key: "dek:$keyID");
    if (data == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "DEK not found for ID $keyID",
      );
    }
    return jsonDecode(data);
  }
}
