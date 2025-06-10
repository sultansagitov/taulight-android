import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taulight/classes/keys.dart';
import 'package:taulight/exceptions.dart';

class KeyStorageService {
  static final KeyStorageService _instance = KeyStorageService._internal();
  static KeyStorageService get ins => _instance;
  KeyStorageService._internal();

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> saveServerKey(ServerKey key) async {
    await _secureStorage.write(
      key: "key:${key.address}",
      value: jsonEncode(key.toMap()),
    );
  }

  Future<void> savePersonalKey(
    String address,
    String keyID,
    PersonalKey key,
  ) async {
    await _secureStorage.write(
      key: "personal:$address:$keyID",
      value: jsonEncode(key.toMap()),
    );
  }

  Future<void> saveEncryptor(
    String address,
    String nickname,
    EncryptorKey key,
  ) async {
    await _secureStorage.write(
      key: "encryptor:$address:$nickname",
      value: jsonEncode(key.toMap()),
    );
  }

  Future<void> saveDEK(
    String address,
    String nickname,
    DEK dek,
  ) async {
    final json = jsonEncode(dek.toMap());
    await _secureStorage.write(key: "dek:$address:$nickname", value: json);
    await _secureStorage.write(key: "dek:$address:${dek.keyId}", value: json);
  }

  Future<ServerKey> loadServerKey(String address) async {
    final data = await _secureStorage.read(key: "key:$address");
    if (data == null) {
      throw KeyStorageNotFoundException("Address $address");
    }
    return ServerKey.fromMap(jsonDecode(data));
  }

  Future<PersonalKey> loadPersonalKey(String address, String keyID) async {
    final data = await _secureStorage.read(key: "personal:$address:$keyID");
    if (data == null) {
      throw KeyStorageNotFoundException("ID $keyID");
    }
    return PersonalKey.fromMap(jsonDecode(data));
  }

  Future<EncryptorKey> loadEncryptor(String address, String nickname) async {
    final data = await _secureStorage.read(key: "encryptor:$address:$nickname");
    if (data == null) {
      throw KeyStorageNotFoundException("Address $address nickname $nickname");
    }
    return EncryptorKey.fromMap(jsonDecode(data));
  }

  Future<DEK> loadDEK(String address, String nickname) async {
    final data = await _secureStorage.read(key: "dek:$address:$nickname");
    if (data == null) {
      throw KeyStorageNotFoundException("Nickname $nickname");
    }
    return DEK.fromMap(jsonDecode(data));
  }

  Future<DEK> loadDEKByID(String address, String keyID) async {
    final data = await _secureStorage.read(key: "dek:$address:$keyID");
    if (data == null) {
      throw KeyStorageNotFoundException("ID $keyID");
    }
    return DEK.fromMap(jsonDecode(data));
  }
}
