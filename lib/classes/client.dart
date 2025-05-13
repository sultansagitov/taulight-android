import 'package:flutter/material.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/services/java_service.dart';
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
  final String name;
  final String uuid;
  final String link;
  final String endpoint;
  final Map<String, TauChat> chats = {};

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
    required this.name,
    required this.uuid,
    required this.endpoint,
    required this.link,
  }) {
    filter = Filter(name, (chat) => chat.client == this);
  }

  ClientStatus get status {
    if (!connected) return ClientStatus.disconnected;
    if (user == null || !user!.authorized) return ClientStatus.unauthorized;
    if (user!.expiredToken) return ClientStatus.expired;
    return ClientStatus.connected;
  }

  TauChat get(String id) => chats[id]!;

  Future<TauChat> load(String id) async => chats[id] = await loadChat(id);

  /// Sends a message to the given chat.
  ///
  /// Returns the sent message.
  ///
  Future<String> sendMessage(TauChat chat, ChatMessageViewDTO message) async {
    return await JavaService.instance.sendMessage(this, chat, message);
  }

  /// Gets a chat with the given ID.
  ///
  /// Returns the chat.
  ///
  Future<TauChat> getOrLoadChat(ChatDTO record) async =>
      await getOrLoadChatByID(record.id);

  /// Gets a chat with the given ID.
  ///
  /// Returns the chat.
  ///
  Future<TauChat> getOrLoadChatByID(String chatID) async {
    if (!chats.containsKey(chatID)) {
      await load(chatID);
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
  Future<List<TauChat>> loadChats() async {
    List<ChatDTO> loadedChats = await JavaService.instance.loadChats(this);
    return loadedChats
        .map((dto) => chats[dto.id] = TauChat.fromRecord(this, dto))
        .toList();
  }

  /// Disconnects the client.
  ///
  Future<void> disconnect() async {
    await JavaService.instance.disconnect(this);
  }

  /// Loads a chat with the given ID.
  ///
  /// Returns the loaded chat.
  ///
  Future<TauChat> loadChat(String id) async {
    return await JavaService.instance.loadChat(this, id);
  }

  /// Creates a channel with the given title.
  ///
  /// Returns the created channel.
  ///
  Future<String> createChannel(String title) async {
    return await JavaService.instance.createChannel(this, title);
  }

  /// Authenticates the client using the provided token.
  /// Stores the authenticated client and token if `store: true`,
  /// initializes `client.user` with a new `User` instance,
  ///
  /// Returns the nickname of the user.
  ///
  Future<String> authByToken(String token, {bool store = true}) async {
    return await JavaService.instance.authByToken(this, token);
  }

  /// Reloads the client.
  ///
  /// Disconnects the client, reconnects it, and reloads the user.
  ///
  Future<void> reload() async {
    await disconnect();
    await JavaService.instance.reconnect(this);
    await user?.reloadIfUnauthorized();
    if (!authorized) return;
    await loadChats();
  }

  /// Uses the given code.
  ///
  Future<void> useCode(String code) async {
    return await JavaService.instance.useCode(this, code);
  }

  /// Creates a dialog with the given nickname.
  ///
  /// Returns the created dialog.
  ///
  Future<TauChat?> createDialog(String nickname) async {
    return await JavaService.instance.createDialog(this, nickname);
  }

  /// Checks the code.
  ///
  /// Returns the code information.
  ///
  Future<CodeDTO> checkCode(String code) async {
    var map = await JavaService.instance.checkCode(this, code);
    return CodeDTO.fromMap(map);
  }

  Future<void> react(ChatMessageViewDTO message, String reactionType) async {
    await JavaService.instance.react(this, message, reactionType);
  }

  Future<void> unreact(ChatMessageViewDTO message, String reactionType) async {
    await JavaService.instance.unreact(this, message, reactionType);
  }

  @override
  String toString() {
    return "Client{$uuid $endpoint ${status.name} chats=${chats.length} $user}";
  }
}
