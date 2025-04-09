import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/utils.dart';

class StorageService {
  static final _storage = FlutterSecureStorage();

  static Future<Map<String, ServerRecord>> getClients() async {
    String? serversStr = await _storage.read(key: "servers");

    if (serversStr != null) {
      print("from storage: $serversStr");
      var decoded = Map<String, Object>.from(jsonDecode(serversStr));
      Map<String, ServerRecord> l = {};
      for (MapEntry<String, Object> entry in decoded.entries) {
        l[entry.key] = ServerRecord.fromJSON(entry.value);
      }
      return l;
    }

    return {};
  }

  static Future<void> saveClients(Map<String, ServerRecord> map) async {
    Map<String, Map<String, Object>> forEncode = {};

    for (MapEntry<String, ServerRecord> entry in map.entries) {
      forEncode[entry.key] = entry.value.toMap();
    }

    await _storage.write(key: "servers", value: jsonEncode(forEncode));
  }

  static Future<void> saveClient(Client client) async {
    Map<String, ServerRecord> map = await getClients();
    map[client.uuid] = ServerRecord(
      name: client.name,
      link: client.link,
    );
    await saveClients(map);
  }

  static Future<void> saveWithToken(
    Client client,
    UserRecord userRecord,
  ) async {
    Map<String, ServerRecord> map = await getClients();

    var serverRecord = map[client.uuid]!;
    serverRecord.user = userRecord;

    await saveClients(map);
  }

  static Future<void> removeToken(Client client) async {
    var map = await getClients();

    if (map.containsKey(client.uuid)) {
      map[client.uuid]!.user = null;
      await saveClients(map);
    } else {
      throw ClientNotFoundException(client.uuid);
    }

    await saveClients(map);
  }

  static Future<void> removeClient(Client client) async {
    var map = await getClients();

    if (map.containsKey(client.uuid)) {
      map.remove(client.uuid);
      await saveClients(map);
    } else {
      throw ClientNotFoundException(client.uuid);
    }

    await saveClients(map);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
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
