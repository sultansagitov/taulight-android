import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/nickname.dart';
import 'package:taulight/classes/uuid.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/utils.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get ins => _instance;
  StorageService._internal();

  final _storage = FlutterSecureStorage();

  Future<Map<UUID, ServerRecord>> getClients() async {
    Map<String, String> all = await _storage.readAll();
    Map<UUID, ServerRecord> clients = {};

    for (final entry in all.entries) {
      if (entry.key.startsWith('server.')) {
        UUID uuid = UUID.fromString(entry.key.substring(7));
        clients[uuid] = ServerRecord.fromJSON(jsonDecode(entry.value));
      }
    }

    return clients;
  }

  Future<ServerRecord?> getClient(UUID uuid) async {
    String? s = await _storage.read(key: "server.$uuid");
    return s != null ? ServerRecord.fromJSON(jsonDecode(s)) : null;
  }

  Future<void> saveClients(Map<String, ServerRecord> map) async {
    for (MapEntry<String, ServerRecord> entry in map.entries) {
      await _storage.write(
        key: 'server.${entry.key}',
        value: jsonEncode(entry.value.toMap()),
      );
    }
  }

  Future<void> saveClient(Client client) async {
    ServerRecord server = ServerRecord(
      name: client.name,
      link: client.link!,
    );
    await _storage.write(
      key: 'server.${client.uuid}',
      value: jsonEncode(server.toMap()),
    );
  }

  Future<void> saveWithToken(Client client, UserRecord userRecord) async {
    String key = 'server.${client.uuid}';
    String? data = await _storage.read(key: key);

    if (data == null) {
      throw ClientNotFoundException(client.uuid);
    }

    ServerRecord server = ServerRecord.fromJSON(jsonDecode(data));
    server.user = userRecord;

    await _storage.write(key: key, value: jsonEncode(server.toMap()));
  }

  Future<void> removeToken(Client client) async {
    String key = 'server.${client.uuid}';
    String? data = await _storage.read(key: key);

    if (data == null) {
      throw ClientNotFoundException(client.uuid);
    }

    ServerRecord server = ServerRecord.fromJSON(jsonDecode(data));
    server.user = null;

    await _storage.write(key: key, value: jsonEncode(server.toMap()));
  }

  Future<void> removeClient(Client client) async {
    String key = 'server.${client.uuid}';
    bool exists = await _storage.containsKey(key: key);

    if (!exists) {
      throw ClientNotFoundException(client.uuid);
    }

    await _storage.delete(key: key);
  }

  Future<bool?> getFingerprintEnabled() async {
    return await _storage.read(key: "fp") == "true";
  }

  Future<void> setFingerprintEnabled() async {
    return await _storage.write(key: "fp", value: "true");
  }

  Future<void> setFingerprintDisabled() async {
    return await _storage.write(key: "fp", value: "false");
  }

  Future<String?> getPIN() async {
    return await _storage.read(key: "pin");
  }

  Future<void> setPIN(String pin) async {
    await _storage.write(key: "pin", value: pin);
  }

  Future<void> cleanPIN() async {
    await _storage.delete(key: "pin");
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

class UserRecord {
  Nickname nickname;
  String token;

  UserRecord(this.nickname, this.token);

  factory UserRecord.fromMap(map) =>
      UserRecord(Nickname.checked(map["nickname"]), map["token"]!);

  Map<String, String> toMap() => {
        "nickname": nickname.toString(),
        "token": token,
      };
}

class ServerRecord {
  String name;
  String link;
  UserRecord? user;

  String get address => link2address(link);

  ServerRecord({required this.name, required this.link, this.user});

  factory ServerRecord.fromJSON(dynamic json) {
    final map = Map<String, dynamic>.from(json);
    final String name = map["name"]!;
    final String link = map["link"]!;
    final userMap = map["user"];

    if (userMap == null) {
      return ServerRecord(name: name, link: link);
    }

    UserRecord userRecord = UserRecord.fromMap(userMap);
    return ServerRecord(name: name, link: link, user: userRecord);
  }

  Map<String, dynamic> toMap() => {
        "name": name,
        "link": link,
        if (user != null) "user": user!.toMap(),
      };
}
