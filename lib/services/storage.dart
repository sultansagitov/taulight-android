import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/utils.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get ins => _instance;
  StorageService._internal();

  final _storage = FlutterSecureStorage();

  Future<Map<String, ServerRecord>> getClients() async {
    Map<String, String> all = await _storage.readAll();
    Map<String, ServerRecord> clients = {};

    for (var entry in all.entries) {
      if (entry.key.startsWith('server.')) {
        String uuid = entry.key.substring(7);
        clients[uuid] = ServerRecord.fromJSON(jsonDecode(entry.value));
      }
    }

    return clients;
  }

  Future<ServerRecord?> getClient(String uuid) async {
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
      link: client.link,
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

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

class UserRecord {
  String nickname;
  String token;
  String keyID;

  UserRecord(this.nickname, this.token, this.keyID);

  factory UserRecord.fromJSON(dynamic json) {
    var map = Map<String, String>.from(json);
    return UserRecord(map["nickname"]!, map["token"]!, map["key-id"]!);
  }

  Map<String, String> toMap() {
    return {"nickname": nickname, "token": token, "key-id": keyID};
  }
}

class ServerRecord {
  String name;
  String link;
  UserRecord? user;

  String get address => link2address(link);

  ServerRecord({required this.name, required this.link, this.user});

  factory ServerRecord.fromJSON(dynamic json) {
    Map<String, dynamic> map = Map<String, dynamic>.from(json);
    String name = map["name"]! as String;
    String link = map["link"]! as String;
    dynamic userMap = map["user"];

    if (userMap == null) {
      return ServerRecord(name: name, link: link);
    }

    UserRecord userRecord = UserRecord.fromJSON(userMap);
    return ServerRecord(name: name, link: link, user: userRecord);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {"name": name, "link": link};
    if (user != null) {
      map["user"] = user!.toMap();
    }
    return map;
  }
}
