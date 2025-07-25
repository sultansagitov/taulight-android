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
      key: "server:${key.address}",
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

  Future<void> saveDEK(String address, String nickname, DEK dek) async {
    final json = jsonEncode(dek.toMap());
    await _secureStorage.write(key: "dek:id:${dek.keyId}", value: json);
    final nicknameKey = "dek:nickname:$address:$nickname";
    await _secureStorage.write(key: nicknameKey, value: dek.keyId);
  }

  Future<List<ServerKey>> loadAllServerKeys() async {
    final all = await _secureStorage.readAll();
    return all.entries
        .where((e) => e.key.startsWith('server:'))
        .map((e) => ServerKey.fromMap(jsonDecode(e.value)))
        .toList();
  }

  Future<ServerKey> loadServerKey(String address) async {
    final data = await _secureStorage.read(key: "server:$address");
    if (data == null) {
      throw KeyStorageNotFoundException("Address $address");
    }
    return ServerKey.fromMap(jsonDecode(data));
  }

  Future<List<PersonalKey>> loadAllPersonalKeys() async {
    final all = await _secureStorage.readAll();
    return all.entries
        .where((e) => e.key.startsWith('personal:'))
        .map((e) => PersonalKey.fromMap(jsonDecode(e.value)))
        .toList();
  }

  Future<PersonalKey> loadPersonalKey(String address, String keyID) async {
    final data = await _secureStorage.read(key: "personal:$address:$keyID");
    if (data == null) {
      throw KeyStorageNotFoundException("ID $keyID");
    }
    return PersonalKey.fromMap(jsonDecode(data));
  }

  Future<List<EncryptorKey>> loadAllEncryptors() async {
    final all = await _secureStorage.readAll();
    return all.entries
        .where((e) => e.key.startsWith('encryptor:'))
        .map((e) => EncryptorKey.fromMap(jsonDecode(e.value)))
        .toList();
  }

  Future<EncryptorKey> loadEncryptor(String address, String nickname) async {
    final data = await _secureStorage.read(key: "encryptor:$address:$nickname");
    if (data == null) {
      throw KeyStorageNotFoundException("Address $address nickname $nickname");
    }
    return EncryptorKey.fromMap(jsonDecode(data));
  }

  Future<List<DEK>> loadAllDEKs() async {
    final all = await _secureStorage.readAll();
    final seen = <String>{};
    final deks = <DEK>[];

    for (final entry in all.entries) {
      if (entry.key.startsWith('dek:id:')) {
        final json = jsonDecode(entry.value);
        final dek = DEK.fromMap(json);
        if (seen.add(dek.keyId)) {
          deks.add(dek);
        }
      }
    }

    return deks;
  }

  Future<DEK> loadDEK(String address, String nickname) async {
    final keyId =
        await _secureStorage.read(key: "dek:nickname:$address:$nickname");
    if (keyId == null) {
      throw KeyStorageNotFoundException("Nickname $nickname");
    }

    final data = await _secureStorage.read(key: "dek:id:$keyId");
    if (data == null) {
      throw KeyStorageNotFoundException("DEK for keyId $keyId not found");
    }

    return DEK.fromMap(jsonDecode(data));
  }

  Future<DEK> loadDEKByID(String keyID) async {
    final data = await _secureStorage.read(key: "dek:id:$keyID");
    if (data == null) {
      throw KeyStorageNotFoundException("ID $keyID");
    }
    return DEK.fromMap(jsonDecode(data));
  }
}
