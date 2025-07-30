import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taulight/classes/keys.dart';
import 'package:taulight/exceptions.dart';

class KeyStorageService {
  static final KeyStorageService _instance = KeyStorageService._internal();
  static KeyStorageService get ins => _instance;
  KeyStorageService._internal();

  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> saveServerKey(ServerKey key) async {
    await _storage.write(
      key: "server:address:${key.address}",
      value: jsonEncode(key.toMap()),
    );
  }

  Future<void> savePersonalKey({
    required String address,
    required String nickname,
    required PersonalKey key,
  }) async {
    await _storage.write(
      key: "personal:address:$address:nickname:$nickname",
      value: jsonEncode(key.toMap()),
    );
  }

  Future<void> saveEncryptor({
    required String address,
    required String nickname,
    required EncryptorKey key,
  }) async {
    await _storage.write(
      key: "encryptor:address:$address:nickname:$nickname",
      value: jsonEncode(key.toMap()),
    );
  }

  Future<void> saveDEK({
    required String address,
    required String nickname,
    required DEK dek,
  }) async {
    final json = jsonEncode(dek.toMap());
    await _storage.write(key: "dek:id:${dek.keyId}", value: json);
    final nicknameKey = "dek:address:$address:nickname:$nickname:id";
    await _storage.write(key: nicknameKey, value: dek.keyId);
  }

  Future<List<ServerKey>> loadAllServerKeys() async {
    final all = await _storage.readAll();
    return all.entries
        .where((e) => e.key.startsWith('server:'))
        .map((e) => ServerKey.fromMap(jsonDecode(e.value)))
        .toList();
  }

  Future<ServerKey> loadServerKey(String address) async {
    final data = await _storage.read(key: "server:address:$address");
    if (data == null) {
      throw KeyStorageNotFoundException("Address $address");
    }
    return ServerKey.fromMap(jsonDecode(data));
  }

  Future<List<PersonalKey>> loadAllPersonalKeys() async {
    final all = await _storage.readAll();
    return all.entries
        .where((e) => e.key.startsWith('personal:'))
        .map((e) => PersonalKey.fromMap(jsonDecode(e.value)))
        .toList();
  }

  Future<PersonalKey> loadPersonalKey({
    required String address,
    required String nickname,
  }) async {
    final data = await _storage.read(
        key: "personal:address:$address:nickname:$nickname");
    if (data == null) {
      throw KeyStorageNotFoundException("Nickname $nickname");
    }
    return PersonalKey.fromMap(jsonDecode(data));
  }

  Future<List<EncryptorKey>> loadAllEncryptors() async {
    final all = await _storage.readAll();
    return all.entries
        .where((e) => e.key.startsWith('encryptor:'))
        .map((e) => EncryptorKey.fromMap(jsonDecode(e.value)))
        .toList();
  }

  Future<EncryptorKey> loadEncryptor({
    required String address,
    required String nickname,
  }) async {
    final data = await _storage.read(
        key: "encryptor:address:$address:nickname:$nickname");
    if (data == null) {
      throw KeyStorageNotFoundException("Address $address nickname $nickname");
    }
    return EncryptorKey.fromMap(jsonDecode(data));
  }

  Future<List<DEK>> loadAllDEKs() async {
    final all = await _storage.readAll();
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

  Future<DEK> loadDEK({
    required String address,
    required String nickname,
  }) async {
    final id =
        await _storage.read(key: "dek:address:$address:nickname:$nickname:id");
    if (id == null) {
      throw KeyStorageNotFoundException("Address $address Nickname $nickname");
    }

    final data = await _storage.read(key: "dek:id:$id");
    if (data == null) {
      throw KeyStorageNotFoundException("DEK for keyId $id not found");
    }

    return DEK.fromMap(jsonDecode(data));
  }

  Future<DEK> loadDEKByID(String keyID) async {
    final data = await _storage.read(key: "dek:id:$keyID");
    if (data == null) {
      throw KeyStorageNotFoundException("ID $keyID");
    }
    return DEK.fromMap(jsonDecode(data));
  }
}
