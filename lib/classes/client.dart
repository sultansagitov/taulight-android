import 'package:flutter/material.dart';
import 'package:taulight/classes/filter.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/classes/uuid.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform/chats.dart';
import 'package:taulight/services/platform/client.dart';

enum ClientStatus {
  connecting("Connecting", Colors.blue),
  connected("Connected", Colors.green),
  unauthorized("Unauthorized", Colors.amber),
  expired("Expired Token", Colors.amber),
  disconnected("Disconnected", Colors.red);

  final String str;
  final Color color;

  const ClientStatus(this.str, this.color);
}

class Client {
  final UUID uuid;
  final String address;
  final Map<UUID, TauChat> chats = {};

  String? link;
  String? realName;
  String get name => realName ?? address;

  bool hide = false;

  bool connecting = false;

  bool _connected = false;
  bool get connected => _connected;

  bool get authorized => connected && user != null && user!.authorized;

  late Filter filter;

  User? user;

  set connected(bool value) {
    connecting = false;
    _connected = value;
    if (value) {
      hide = false;
    } else {
      user?.authorized = false;
    }
  }

  Client({required this.uuid, required this.address, this.link}) {
    if (address.isEmpty) throw ArgumentError("Address is empty");
    if (link != null) validateLink(link!);
  }

  static void validateLink(String link) {
    if (!link.startsWith("sandnode://")) {
      throw InvalidSandnodeLinkException("Not sandnode scheme");
    }
    
    if (!(link.contains("encryption=") && link.contains("key="))) {
      throw InvalidSandnodeLinkException("Link have no key");
    }
  }

  ClientStatus get status {
    if (connecting) return ClientStatus.connecting;
    if (!connected) return ClientStatus.disconnected;
    if (user == null || !user!.authorized) return ClientStatus.unauthorized;
    if (user!.expiredToken) return ClientStatus.expired;
    return ClientStatus.connected;
  }

  TauChat get(UUID id) => chats[id]!;

  Future<TauChat> save(UUID id) async => chats[id] = await loadChat(id);

  /// Gets a chat with the given ID.
  ///
  /// Returns the chat.
  ///
  Future<TauChat> getOrSaveChatByID(UUID chatID) async {
    if (!chats.containsKey(chatID)) {
      await save(chatID);
    }

    return get(chatID);
  }

  /// Gets a chat with the given ID.
  ///
  /// Returns the chat.
  ///
  TauChat? getChatByID(UUID chatID) {
    return chats[chatID];
  }

  /// Loads all chats.
  ///
  /// You should check `user.authorized` before call
  ///
  /// Returns the loaded chats.
  ///
  Future<void> loadChats() async {
    for (final dto in await PlatformChatsService.ins.loadChats(this)) {
      chats[dto.id] ??= TauChat(this, dto);
      chats[dto.id]!.avatarID = dto.avatarID;
    }
  }

  /// Disconnects the client.
  ///
  Future<void> disconnect() => PlatformClientService.ins.disconnect(this);

  Future<void> resetName() async {
    realName = await PlatformClientService.ins.name(this);
  }

  /// Loads a chat with the given ID.
  ///
  /// Returns the loaded chat.
  ///
  Future<TauChat> loadChat(UUID id) =>
      PlatformChatsService.ins.loadChat(this, id);

  /// Reloads the client.
  ///
  /// Disconnects the client, reconnects it, and reloads the user.
  ///
  Future<void> reload() async {
    await disconnect();
    await PlatformClientService.ins.reconnect(this);
    await user?.reloadIfUnauthorized();
    if (!authorized) return;
    await loadChats();
  }

  @override
  String toString() {
    return "Client{$uuid $address ${status.name} chats=${chats.length} $user}";
  }
}
