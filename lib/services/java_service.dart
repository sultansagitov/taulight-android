import 'package:flutter/services.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/utils.dart';
import 'package:uuid/uuid.dart';

import 'package:taulight/exceptions.dart';

final invalidLinkExceptions = [
  "InvalidSandnodeLinkException",
  "CreatingKeyException",
];

final disconnectExceptions = [
  "InterruptedException",
  "UnexpectedSocketDisconnectException",
];

final incorrectUserDataExceptions = [
  "UnauthorizedException",
  "MemberNotFoundException",
];

abstract class Result {}

class ExceptionResult extends Result implements Exception {
  final String name;
  final String? msg;

  ExceptionResult(this.name, [this.msg]);

  @override
  String toString() => "Java - $name: $msg";
}

class SuccessResult extends Result {
  final Object? obj;
  SuccessResult(this.obj);
}

class JavaService {
  static final JavaService _instance = JavaService._internal();
  static JavaService get instance => _instance;
  JavaService._internal();

  static const methodChannelName = 'net.result.taulight/messenger';
  final MethodChannel platform = MethodChannel(methodChannelName);

  final Map<String, Client> clients = {};

  void setMethodCallHandler(Future Function(MethodCall call)? handler) {
    platform.setMethodCallHandler(handler);
  }

  Client? getClientByUUID(String uuid) => clients[uuid];

  Future<Result> method(String methodName, Map<String, Object> args) async {
    print("Called on platform --- \"$methodName\"");
    Map result = (await platform.invokeMethod<Map>(methodName, args))!;

    var error = result["error"];
    if (error != null) {
      return ExceptionResult(error["name"], error["message"]);
    }

    return SuccessResult(result["success"]);
  }

  Future<Result> chain(
    String methodName, {
    required Client client,
    List<String>? params,
  }) {
    Map<String, Object> args = {"uuid": client.uuid, "method": methodName};
    if (params != null) args["params"] = params;
    return method("chain", args);
  }

  Future<Client> connect(
    String link, {
    VoidCallback? connectUpdate,
    bool keep = false,
  }) async {
    String uuid = Uuid().v4();
    return await connectWithUUID(
      uuid,
      link,
      connectUpdate: connectUpdate,
      keep: keep,
    );
  }

  Future<Client> connectWithUUID(
    String uuid,
    String link, {
    VoidCallback? connectUpdate,
    bool keep = false,
  }) async {
    String endpoint;
    try {
      endpoint = link2endpoint(link);
    } catch (e) {
      throw InvalidSandnodeLinkException(link);
    }

    Result result = await method("connect", {"uuid": uuid, "link": link});

    Client client = Client(
      name: endpoint,
      uuid: uuid,
      endpoint: endpoint,
      link: link,
    );

    if (keep) clients[uuid] = client;

    connectUpdate?.call();

    if (result is ExceptionResult) {
      if (invalidLinkExceptions.contains(result.name)) {
        throw InvalidSandnodeLinkException(link);
      }
      if (result.name == "ConnectionException") {
        throw ConnectionException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      client.connected = true;
      if (!keep) clients[uuid] = client;
      connectUpdate?.call();
      return client;
    }
    throw IncorrectFormatChannelException();
  }

  Future<void> reconnect(Client client, [VoidCallback? callback]) async {
    String uuid = client.uuid;
    String link = client.link;
    Result result = await method("connect", {"uuid": uuid, "link": link});

    callback?.call();

    if (result is ExceptionResult) {
      if (invalidLinkExceptions.contains(result.name)) {
        throw InvalidSandnodeLinkException(link);
      }
      if (result.name == "ConnectionException") {
        throw ConnectionException(client);
      }
      throw result;
    }

    client.connected = true;
    callback?.call();
  }

  Future<List<ChatDTO>> loadChats(Client client) async {
    Map<String, String> arguments = {"uuid": client.uuid};
    Result result = await method("get-chats", arguments);

    if (result is ExceptionResult) {
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      if (result.name == "ClientNotFoundException") {
        throw BackClientNotFoundException(client);
      }
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      var list = result.obj;
      if (list is List) {
        return list
            .where((obj) => ["cn", "dl"].contains(obj["type"]))
            .map((v) => ChatDTO.fromMap(client, v))
            .toList();
      }
    }
    throw IncorrectFormatChannelException();
  }

  Future<TauChat> loadChat(Client client, String id) async {
    var uuid = client.uuid;
    var result = await method("load-chat", {"uuid": uuid, "chat-id": id});

    if (result is ExceptionResult) {
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      if (result.name == "ChatNotFoundException") {
        throw ChatNotFoundException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      var dto = ChatDTO.fromMap(client, result.obj);
      return TauChat.fromRecord(client, dto);
    }

    throw IncorrectFormatChannelException();
  }

  Future<int> loadMessages(TauChat chat, int i, int size) async {
    var result = await method("load-messages", {
      "uuid": chat.client.uuid,
      "chat-id": chat.id,
      "index": i,
      "size": size,
    });

    if (result is ExceptionResult) {
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(chat.client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      print("Loading messages: $chat ${result.obj}");
      var obj = result.obj;
      if (obj is Map) {
        var messages = obj["messages"];
        for (var json in messages) {
          var message = ChatMessageViewDTO.fromMap(chat.client, json);
          chat.addMessage(message);
        }
        return obj["count"];
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<void> disconnect(Client client) async {
    if (client.connected) {
      String uuid = client.uuid;
      Result result = await method("disconnect", {"uuid": uuid});

      if (result is ExceptionResult) {
        throw result;
      }
    }
  }

  Future<void> loadClients() async {
    Result result = await method("load-clients", {});

    if (result is ExceptionResult) {
      throw result;
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is List) {
        for (var json in obj) {
          var uuid = json["uuid"];
          if (!clients.containsKey(uuid)) {
            clients[uuid] = Client(
              name: json["endpoint"],
              uuid: uuid,
              endpoint: json["endpoint"],
              link: json["link"],
            );
          }
        }
        return;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> createChannel(Client client, String title) async {
    Result result = await chain(
      "ChannelClientChain.sendNewChannelRequest",
      client: client,
      params: [title],
    );

    if (result is ExceptionResult) {
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is String) {
        return obj;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> log(Client client, String nickname, String password) async {
    client.user?.expiredToken = false;
    Result result = await chain(
      "LogPasswdClientChain.getToken",
      client: client,
      params: [nickname, password],
    );
    if (result is ExceptionResult) {
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }

      if (incorrectUserDataExceptions.contains(result.name)) {
        throw IncorrectUserDataException();
      }

      throw result;
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is String) {
        var token = obj;
        client.user = User(client, nickname, token);
        UserRecord userRecord = UserRecord(nickname, token);
        await StorageService.saveWithToken(client, userRecord);
        return token;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> reg(Client client, String nickname, String password) async {
    client.user?.expiredToken = false;
    Result result = await chain(
      "RegistrationClientChain.getTokenFromRegistration",
      client: client,
      params: [nickname, password],
    );

    if (result is ExceptionResult) {
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      if (incorrectUserDataExceptions.contains(result.name)) {
        throw IncorrectUserDataException();
      }
      if (result.name == "ClientNotFoundException") {
        throw BackClientNotFoundException(client);
      }
      if (result.name == "BusyNicknameException") {
        throw BusyNicknameException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is String) {
        client.user = User(client, nickname, obj);
        return obj;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> sendMessage(
    Client client,
    TauChat chat,
    ChatMessageViewDTO message,
  ) async {
    Result result = await method("send", {
      "uuid": client.uuid,
      "chat-id": chat.id,
      "content": message.text,
      "repliedToMessages": message.repliedToMessages,
    });

    if (result is ExceptionResult) {
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is String) {
        return obj;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<List<Member>> getMembers(TauChat chat) async {
    Result result = await chain(
      "MembersClientChain.getMembers",
      client: chat.client,
      params: [chat.id],
    );

    if (result is ExceptionResult) {
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(chat.client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is List) {
        return obj.map((m) => Member.fromMap(m)).toList();
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> authByToken(Client client, String token) async {
    client.user?.expiredToken = false;
    Result result = await chain(
      "LoginClientChain.getNickname",
      client: client,
      params: [token],
    );

    if (result is ExceptionResult) {
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      if (result.name == "ExpiredTokenException") {
        throw ExpiredTokenException(client);
      }
      if (result.name == "InvalidTokenException") {
        throw InvalidTokenException(client);
      }
      if (result.name == "ClientNotFoundException") {
        throw BackClientNotFoundException(client);
      }
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is String) {
        String nickname = obj;
        StorageService.saveWithToken(client, UserRecord(nickname, token));
        client.user = User(client, nickname, token);
        return obj;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> addMember(Client client, TauChat chat, String nickname) async {
    Result result = await method("add-member", {
      "uuid": client.uuid,
      "chat-id": chat.id,
      "nickname": nickname,
    });

    if (result is ExceptionResult) {
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(client);
      }
      if (result.name == "NotFound") {
        throw NotFoundException(client, chat);
      }
      if (result.name == "AddressedMemberNotFoundException") {
        throw AddressedMemberNotFoundException(client, nickname);
      }
      if (result.name == "NoEffectException") {
        throw NoEffectException(nickname);
      }
      throw result;
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is Map && obj.containsKey("code")) {
        return obj["code"];
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<Map<String, dynamic>> checkCode(Client client, String code) async {
    Result result = await chain(
      "CheckCodeClientChain.check",
      client: client,
      params: [code],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw NotFoundException(client, code);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      return Map<String, dynamic>.from(result.obj as Map);
    }

    throw IncorrectFormatChannelException();
  }

  Future<void> useCode(Client client, String code) async {
    Result result = await chain(
      "UseCodeClientChain.use",
      client: client,
      params: [code],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw NotFoundException(client, code);
      }
      if (result.name == "NoEffectException") {
        throw NoEffectException(code);
      }
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(client);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }
  }

  Future<TauChat?> createDialog(Client client, String nickname) async {
    Result result = await chain(
      "DialogClientChain.getDialogID",
      client: client,
      params: [nickname],
    );

    if (result is ExceptionResult) {
      if (result.name == "AddressedMemberNotFoundException") {
        throw AddressedMemberNotFoundException(client, nickname);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is String) {
        return await client.loadChat(obj);
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<void> leaveChat(Client client, TauChat chat) async {
    Result result = await chain(
      "ChannelClientChain.sendLeaveRequest",
      client: client,
      params: [chat.id],
    );

    if (result is ExceptionResult) {
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(client);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }
  }

  Future<List<Map<String, dynamic>>> getChannelCodes(
    Client client,
    TauChat chat,
  ) async {
    Result result = await chain(
      "ChannelClientChain.getChannelCodes",
      client: client,
      params: [chat.id],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(client);
      }
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(client);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      List<dynamic> invites = result.obj as List<dynamic>;
      return invites
          .map((invite) => Map<String, dynamic>.from(invite as Map))
          .toList();
    }

    throw IncorrectFormatChannelException();
  }

  Future<void> react(
    Client client,
    ChatMessageViewDTO message,
    String reactionType,
  ) async {
    Result result = await chain(
      "ReactionRequestClientChain.react",
      client: client,
      params: [message.id, reactionType],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(client);
      }
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(client);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }
  }

  Future<void> unreact(
    Client client,
    ChatMessageViewDTO message,
    String reactionType,
  ) async {
    Result result = await chain(
      "ReactionRequestClientChain.unreact",
      client: client,
      params: [message.id, reactionType],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(client);
      }
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(client);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }
  }

  Future<void> setChannelAvatar(
    Client client,
    ChannelDTO channel,
    String imagePath,
  ) async {
    var result = await chain(
      "ChannelClientChain.setAvatar",
      client: client,
      params: [channel.id, imagePath],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(client);
      }
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(client);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }
  }

  Future<Map<String, String>> getChannelAvatar(
    Client client,
    ChannelDTO channel,
  ) async {
    Result result = await method("get-channel-avatar", {
      "uuid": client.uuid,
      "chat-id": channel.id,
    });

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(client);
      }
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(client);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      return Map<String, String>.from(result.obj as Map);
    }

    throw IncorrectFormatChannelException();
  }
}
