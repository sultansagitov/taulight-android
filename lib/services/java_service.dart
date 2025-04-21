import 'package:flutter/services.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/user.dart';
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
  final Object obj;
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
    Map result = (await platform.invokeMethod<Map>(methodName, args))!;

    var error = result["error"];
    if (error != null) {
      return ExceptionResult(error["name"], error["message"]);
    }

    return SuccessResult(result["success"]);
  }

  Future<Client> connect(String link, [VoidCallback? callback]) async {
    String uuid = Uuid().v4();
    return await connectWithUUID(uuid, link, callback);
  }

  Future<Client> connectWithUUID(String uuid, String link,
      [VoidCallback? callback]) async {
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
    clients[uuid] = client;

    if (callback != null) callback();

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
      if (callback != null) callback();
      return client;
    }
    throw IncorrectFormatChannelException();
  }

  Future<void> reconnect(Client client, [VoidCallback? callback]) async {
    String uuid = client.uuid;
    String link = client.link;
    Result result = await method("connect", {"uuid": uuid, "link": link});

    if (callback != null) callback();

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
      if (callback != null) callback();
      return;
    }
    throw IncorrectFormatChannelException();
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
            .map(ChatDTO.fromMap)
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
      return TauChat.fromRecord(client, ChatDTO.fromMap(result.obj));
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
    Result result = await method("create-channel", {
      "uuid": client.uuid,
      "title": title,
    });

    if (result is ExceptionResult) {
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is Map) {
        return obj["chat-id"];
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> log(Client client, String nickname, String passwd) async {
    Result result = await method("login", {
      "uuid": client.uuid,
      "nickname": nickname,
      "password": passwd,
    });

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
      if (obj is Map) {
        String token = obj["token"];
        client.user = User(client, nickname, token);
        return token;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> reg(Client client, String nickname, String passwd) async {
    Result result = await method("register", {
      "uuid": client.uuid,
      "nickname": nickname,
      "password": passwd,
    });

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
      if (obj is Map) {
        String token = obj["token"];
        client.user = User(client, nickname, token);
        return token;
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
    Result result = await method("members", {
      "uuid": chat.client.uuid,
      "chat-id": chat.id,
    });

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
    var uuid = client.uuid;
    Result result = await method("token", {"uuid": uuid, "token": token});

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
      if (obj is Map) {
        return obj["nickname"];
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
        throw NotFound(client, chat);
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
    Result result = await method("check-code", {
      "uuid": client.uuid,
      "code": code,
    });

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw NotFoundException(code);
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
    Result result = await method("use-code", {
      "uuid": client.uuid,
      "code": code,
    });

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw NotFoundException(code);
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

    if (result is SuccessResult) {
      return;
    }

    throw IncorrectFormatChannelException();
  }

  Future<TauChat?> createDialog(Client client, String nickname) async {
    Result result = await method("dialog", {
      "uuid": client.uuid,
      "nickname": nickname,
    });

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
      Map<String, dynamic> chatResult =
          Map<String, dynamic>.from(result.obj as Map);
      String chatId = chatResult["chat-id"];
      return await loadChat(client, chatId);
    }

    throw IncorrectFormatChannelException();
  }

  Future<void> leaveChat(Client client, TauChat chat) async {
    Result result = await method("leave", {
      "uuid": client.uuid,
      "chat-id": chat.id,
    });

    if (result is ExceptionResult) {
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(client);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      return;
    }

    throw IncorrectFormatChannelException();
  }

  Future<List<Map<String, dynamic>>> getChannelCodes(
    Client client,
    TauChat chat,
  ) async {
    Result result = await method("channel-codes", {
      "uuid": client.uuid,
      "chat-id": chat.id,
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
    Result result = await method("react", {
      "uuid": client.uuid,
      "message-id": message.id,
      "reaction-type": reactionType
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
      if (result.obj == "success") {
        return;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<void> unreact(
    Client client,
    ChatMessageViewDTO message,
    String reactionType,
  ) async {
    Result result = await method("unreact", {
      "uuid": client.uuid,
      "message-id": message.id,
      "reaction-type": reactionType
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
      if (result.obj == "success") {
        return;
      }
    }

    throw IncorrectFormatChannelException();
  }
}
