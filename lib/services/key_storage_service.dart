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
    return Map<String, String>.from(jsonDecode(keyData));
  }

  Future<void> savePersonalKey(
    String address,
    String keyID,
    String encryption, {
    String? symKey,
    String? publicKey,
    String? privateKey,
  }) async {
    final Map<String, String> data = {
      "encryption": encryption,
      if (symKey != null) ...{
        "sym": symKey,
      } else ...{
        "public": publicKey!,
        "private": privateKey!,
      }
    };
    await _secureStorage.write(
      key: "personal:$address:$keyID",
      value: jsonEncode(data),
    );
  }

  Future<Map<String, String>> loadPersonalKey(
    String address,
    String keyID,
  ) async {
    final data = await _secureStorage.read(key: "personal:$address:$keyID");
    if (data == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "Key not found for ID $keyID",
      );
    }
    return Map<String, String>.from(jsonDecode(data));
  }

  Future<void> saveEncryptor(
    String address,
    String nickname,
    String keyID,
    String encryption, {
    String? symKey,
    String? publicKey,
  }) async {
    final Map<String, String> data = {
      "key-id": keyID,
      "encryption": encryption,
      if (symKey != null) ...{
        "sym": symKey,
      } else ...{
        "public": publicKey!,
      }
    };
    await _secureStorage.write(
      key: "encryptor:$address:$nickname",
      value: jsonEncode(data),
    );
  }

  Future<Map<String, String>> loadEncryptor(
    String address,
    String nickname,
  ) async {
    final String? data = await _secureStorage.read(key: "encryptor:$address:$nickname");
    if (data == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "Encryptor not found",
      );
    }
    return Map<String, String>.from(jsonDecode(data));
  }

  Future<void> saveDEK(
    String address,
    String nickname,
    String keyID,
    String encryption, {
    String? symKey,
    String? publicKey,
    String? privateKey,
  }) async {
    final Map<String, String> data = {
      "key-id": keyID,
      "encryption": encryption,
      if (symKey != null) ...{
        "sym": symKey,
      } else ...{
        "public": publicKey!,
        "private": privateKey!,
      }
    };
    await _secureStorage.write(
      key: "dek:$address:$nickname",
      value: jsonEncode(data),
    );
    await _secureStorage.write(
      key: "dek:$address:$keyID",
      value: jsonEncode(data),
    );
  }

  Future<Map<String, String>> loadDEK(
    String address,
    String nickname,
  ) async {
    final String? data = await _secureStorage.read(key: "dek:$address:$nickname");
    if (data == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "DEK not found for nickname $nickname",
      );
    }
    return Map<String, String>.from(jsonDecode(data));
  }

  Future<Map<String, String>> loadDEKByID(
    String address,
    String keyID,
  ) async {
    final String? data = await _secureStorage.read(key: "dek:$address:$keyID");
    if (data == null) {
      throw PlatformException(
        code: "key_not_found",
        message: "DEK not found for ID $keyID",
      );
    }
    return Map<String, String>.from(jsonDecode(data));
  }
}
