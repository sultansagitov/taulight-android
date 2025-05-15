import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/utils.dart';

class StorageService {

  static final _storage = FlutterSecureStorage();

  static Future<Map<String, ServerRecord>> getClients() async {
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

  static Future<ServerRecord?> getClient(String uuid) async {
    String? s = await _storage.read(key: "server.$uuid");
    return s != null ? ServerRecord.fromJSON(jsonDecode(s)) : null;
  }

  static Future<void> saveClients(Map<String, ServerRecord> map) async {
    for (MapEntry<String, ServerRecord> entry in map.entries) {
      await _storage.write(
        key: 'server.${entry.key}',
        value: jsonEncode(entry.value.toMap()),
      );
    }
  }

  static Future<void> saveClient(Client client) async {
    ServerRecord server = ServerRecord(name: client.name, link: client.link);
    await _storage.write(
      key: 'server.${client.uuid}',
      value: jsonEncode(server.toMap()),
    );
  }

  static Future<void> saveWithToken(Client client, UserRecord userRecord) async {
    String key = 'server.${client.uuid}';
    String? data = await _storage.read(key: key);

    if (data == null) {
      throw ClientNotFoundException(client.uuid);
    }

    ServerRecord server = ServerRecord.fromJSON(jsonDecode(data));
    server.user = userRecord;

    await _storage.write(key: key, value: jsonEncode(server.toMap()));
  }

  static Future<void> removeToken(Client client) async {
    String key = 'server.${client.uuid}';
    String? data = await _storage.read(key: key);

    if (data == null) {
      throw ClientNotFoundException(client.uuid);
    }

    ServerRecord server = ServerRecord.fromJSON(jsonDecode(data));
    server.user = null;

    await _storage.write(key: key, value: jsonEncode(server.toMap()));
  }

  static Future<void> removeClient(Client client) async {
    String key = 'server.${client.uuid}';
    bool exists = await _storage.containsKey(key: key);

    if (!exists) {
      throw ClientNotFoundException(client.uuid);
    }

    await _storage.delete(key: key);
  }

  static Future<void> clear() async {
    Map<String, String> all = await _storage.readAll();
    for (var key in all.keys) {
      if (key.startsWith('server.')) {
        await _storage.delete(key: key);
      }
    }
  }
}

class UserRecord {
  String nickname;
  String token;

  UserRecord(this.nickname, this.token);

  factory UserRecord.fromJSON(dynamic json) {
    var map = Map<String, String>.from(json);
    return UserRecord(map["nickname"]!, map["token"]!);
  }

  Map<String, String> toMap() {
    return {"nickname": nickname, "token": token};
  }
}

class ServerRecord {
  String name;
  String link;
  UserRecord? user;

  ServerRecord({required this.name, required this.link, this.user});

  factory ServerRecord.fromJSON(dynamic json) {
    Map<String, Object> map = Map<String, Object>.from(json);
    String name = map["name"]! as String;
    String link = map["link"]! as String;
    Object? userMap = map["user"];

    if (userMap == null) {
      return ServerRecord(name: name, link: link);
    }

    UserRecord userRecord = UserRecord.fromJSON(userMap);
    return ServerRecord(name: name, link: link, user: userRecord);
  }

  String get endpoint => link2endpoint(link);

  Map<String, Object> toMap() {
    Map<String, Object> map = {"name": name, "link": link};
    if (user != null) {
      map["user"] = user!.toMap();
    }
    return map;
  }
}
