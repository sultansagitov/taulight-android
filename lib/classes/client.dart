import 'package:flutter/material.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/services/platform_service.dart';
import 'package:taulight/widgets/chats_filter.dart';

enum ClientStatus {
  connected("Connected", Colors.green),
  unauthorized("Unauthorized", Colors.amber),
  expired("Expired Token", Colors.amber),
  disconnected("Disconnected", Colors.red);

  final String str;
  final Color color;

  const ClientStatus(this.str, this.color);
}

class Client {
  final String uuid;
  final String link;
  final String endpoint;
  final Map<String, TauChat> chats = {};

  String? realName;
  String get name => realName ?? endpoint;

  bool hide = false;

  bool _connected = false;
  bool get connected => _connected;

  bool get authorized => connected && user != null && user!.authorized;

  late Filter filter;

  User? user;

  set connected(bool value) {
    _connected = value;
    if (value) {
      hide = false;
    } else {
      user?.authorized = false;
    }
  }

  Client({
    required this.uuid,
    required this.endpoint,
    required this.link,
  }) {
    filter = Filter(
      () => (authorized) ? "$name (${user!.nickname})" : name,
      (chat) => chat.client == this,
    );
  }

  ClientStatus get status {
    if (!connected) return ClientStatus.disconnected;
    if (user == null || !user!.authorized) return ClientStatus.unauthorized;
    if (user!.expiredToken) return ClientStatus.expired;
    return ClientStatus.connected;
  }

  TauChat get(String id) => chats[id]!;

  Future<TauChat> save(String id) async => chats[id] = await loadChat(id);

  /// Sends a message to the given chat.
  ///
  /// Returns the sent message.
  ///
  Future<String> sendMessage(TauChat chat, ChatMessageViewDTO message) async {
    return await PlatformService.ins.sendMessage(this, chat, message);
  }

  /// Gets a chat with the given ID.
  ///
  /// Returns the chat.
  ///
  Future<TauChat> getOrSaveChatByID(String chatID) async {
    if (!chats.containsKey(chatID)) {
      await save(chatID);
    }

    return get(chatID);
  }

  /// Gets a chat with the given ID.
  ///
  /// Returns the chat.
  ///
  TauChat? getChatByID(String chatID) {
    return chats[chatID];
  }

  /// Loads all chats.
  ///
  /// You should check `user.authorized` before call
  ///
  /// Returns the loaded chats.
  ///
  Future<void> loadChats() async {
    for (var dto in await PlatformService.ins.loadChats(this)) {
      chats[dto.id] ??= TauChat(this, dto);
    }
  }

  /// Disconnects the client.
  ///
  Future<void> disconnect() async {
    await PlatformService.ins.disconnect(this);
  }

  Future<void> resetName() async {
    realName = await PlatformService.ins.name(this);
  }

  /// Loads a chat with the given ID.
  ///
  /// Returns the loaded chat.
  ///
  Future<TauChat> loadChat(String id) async {
    return await PlatformService.ins.loadChat(this, id);
  }

  /// Creates a channel with the given title.
  ///
  /// Returns the created channel.
  ///
  Future<String> createChannel(String title) async {
    return await PlatformService.ins.createChannel(this, title);
  }

  /// Authenticates the client using the provided token.
  /// Stores the authenticated client and token if `store: true`,
  /// initializes `client.user` with a new `User` instance,
  ///
  /// Returns the nickname of the user.
  ///
  Future<String> authByToken(String token, {bool store = true}) async {
    return await PlatformService.ins.authByToken(this, token);
  }

  /// Reloads the client.
  ///
  /// Disconnects the client, reconnects it, and reloads the user.
  ///
  Future<void> reload() async {
    await disconnect();
    await PlatformService.ins.reconnect(this);
    await user?.reloadIfUnauthorized();
    if (!authorized) return;
    await loadChats();
  }

  /// Uses the given code.
  ///
  Future<void> useCode(String code) async {
    return await PlatformService.ins.useCode(this, code);
  }

  /// Creates a dialog with the given nickname.
  ///
  /// Returns the created dialog.
  ///
  Future<TauChat?> createDialog(String nickname) async {
    return await PlatformService.ins.createDialog(this, nickname);
  }

  /// Checks the code.
  ///
  /// Returns the code information.
  ///
  Future<CodeDTO> checkCode(String code) async {
    var map = await PlatformService.ins.checkCode(this, code);
    return CodeDTO.fromMap(map);
  }

  Future<void> react(ChatMessageViewDTO message, String reactionType) async {
    await PlatformService.ins.react(this, message, reactionType);
  }

  Future<void> unreact(ChatMessageViewDTO message, String reactionType) async {
    await PlatformService.ins.unreact(this, message, reactionType);
  }

  @override
  String toString() {
    return "Client{$uuid $endpoint ${status.name} chats=${chats.length} $user}";
  }
}
