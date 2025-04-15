import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/services/java_service.dart';

class Client {
  final String name;
  final String uuid;
  final String link;
  final String endpoint;
  final Map<String, TauChat> chats = {};

  bool hide = false;
  bool _connected = false;

  bool get connected => _connected;

  set connected(bool value) {
    _connected = value;
    if (value) {
      hide = false;
    } else {
      user?.authorized = false;
    }
  }

  User? user;

  Client({
    required this.name,
    required this.uuid,
    required this.endpoint,
    required this.link,
  });

  String get status {
    if (!connected) return "Disconnected";
    if (user == null) return "Unauthorized";
    return "Connected";
  }

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
  Future<TauChat> getOrLoadChat(ChatDTO record) async {
    if (!chats.containsKey(record.id)) {
      chats[record.id] = await loadChat(record.id);
    }

    return chats[record.id]!;
  }

  /// Gets a chat with the given ID.
  ///
  /// Returns the chat.
  ///
  Future<TauChat> getOrLoadChatByID(String chatID) async {
    if (!chats.containsKey(chatID)) {
      chats[chatID] = await loadChat(chatID);
    }

    return chats[chatID]!;
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
  /// Returns the loaded chats.
  ///
  Future<List<TauChat>> loadChats() async {
    var loadedChats = await JavaService.instance.loadChats(this);
    List<TauChat> res = [];
    for (var record in loadedChats) {
      res.add(await getOrLoadChat(record));
    }
    return res;
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

  /// Authenticates the client with the given token.
  ///
  /// Returns the nickname of the user.
  ///
  Future<String> authByToken(String token) async {
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

  @override
  String toString() {
    var s = connected ? " connected" : "";
    return "Client{$uuid $endpoint chats=${chats.length}$s $user}";
  }
}
