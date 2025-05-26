import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/login_history_dto.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/services/client_service.dart';
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

class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  static PlatformService get ins => _instance;
  PlatformService._internal();

  static const methodChannelName = 'net.result.taulight/messenger';
  final MethodChannel platform = MethodChannel(methodChannelName);
  String? _device;

  void setMethodCallHandler(Future Function(MethodCall call)? handler) {
    platform.setMethodCallHandler(handler);
  }

  Future<Result> method(String methodName, Map<String, dynamic> args) async {
    print("Called on platform --- \"$methodName\"");
    Map result = (await platform.invokeMethod<Map>(methodName, args))!;
    print("Result of \"$methodName\" - $result");

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
    Map<String, dynamic> args = {"uuid": client.uuid, "method": methodName};
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

    // TODO add connecting status

    Client client = Client(
      uuid: uuid,
      endpoint: endpoint,
      link: link,
    );

    if (keep) ClientService.ins.add(client);
    connectUpdate?.call();

    Result result = await method("connect", {"uuid": uuid, "link": link});

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
      if (!keep) ClientService.ins.add(client);
      await client.resetName();
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

  Future<String> name(Client client) async {
    var result = await chain("NameClientChain.getName", client: client);

    if (result is ExceptionResult) {
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
            .where((obj) => ["cn", "dl"].contains(obj["chat"]["type"]!))
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
      return TauChat(client, ChatDTO.fromMap(client, result.obj));
    }

    throw IncorrectFormatChannelException();
  }

  Future<int> loadMessages(TauChat chat, int i, int size) async {
    var result = await method("load-messages", {
      "uuid": chat.client.uuid,
      "chat-id": chat.record.id,
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
          var message = ChatMessageWrapperDTO.fromMap(chat.client, json);
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
      ClientService clientService = ClientService.ins;

      var obj = result.obj;
      if (obj is List) {
        for (var map in obj) {
          String uuid = map["uuid"];
          if (clientService.contains(uuid)) continue;
          Client client = clientService.fromMap(map);
          await client.resetName();
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

    _device ??= (await DeviceInfoPlugin().deviceInfo).data['name'];

    Result result = await chain(
      "LogPasswdClientChain.getToken",
      client: client,
      params: [nickname, password, _device!],
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
      var map = Map<String, String>.from(result.obj);
      var token = map['token']!;
      client.user = User(client, nickname, token);
      UserRecord userRecord = UserRecord(nickname, token);
      await StorageService.ins.saveWithToken(client, userRecord);
      return token;
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> reg(Client client, String nickname, String password) async {
    client.user?.expiredToken = false;

    _device ??= (await DeviceInfoPlugin().deviceInfo).data['name'];

    Result result = await method("register", {
      "uuid": client.uuid,
      "nickname": nickname,
      "password": password,
      "device": _device!,
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
      var map = Map<String, String>.from(result.obj);
      var token = map["token"]!;
      client.user = User(client, nickname, token);
      return token;
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
      "chat-id": chat.record.id,
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
      params: [chat.record.id],
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
    Result result = await method("login", {
      "uuid": client.uuid,
      "token": token,
    });

    if (result is ExceptionResult) {
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(client);
      }
      if (result.name == "ExpiredTokenException") {
        throw ExpiredTokenException(client);
      }
      if (result.name == "InvalidArgumentException") {
        throw InvalidArgumentException(client);
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
        String nickname = obj.trim();
        StorageService.ins.saveWithToken(client, UserRecord(nickname, token));
        client.user = User(client, nickname, token);
        return obj;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> addMember(
      TauChat chat, String nickname, Duration expirationTime) async {
    var client = chat.client;
    Result result = await chain(
      "ChannelClientChain.createInviteCode",
      client: client,
      params: [chat.record.id, nickname, expirationTime.inSeconds.toString()],
    );

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
      if (obj is String) {
        return obj;
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
      params: [chat.record.id],
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
      params: [chat.record.id],
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

  Future<void> setChannelAvatar(TauChat chat, String imagePath) async {
    var result = await chain(
      "ChannelClientChain.setAvatar",
      client: chat.client,
      params: [chat.record.id, imagePath],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(chat.client);
      }
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(chat.client);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(chat.client);
      }
      throw result;
    }
  }

  Future<Map<String, String>> getChannelAvatar(TauChat chat) async {
    Result result = await method("get-channel-avatar", {
      "uuid": chat.client.uuid,
      "chat-id": chat.record.id,
    });

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(chat.client);
      }
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(chat.client);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(chat.client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      return Map<String, String>.from(result.obj as Map);
    }

    throw IncorrectFormatChannelException();
  }

  Future<Map<String, String>> getDialogAvatar(TauChat chat) async {
    Result result = await method("get-dialog-avatar", {
      "uuid": chat.client.uuid,
      "chat-id": chat.record.id,
    });

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(chat.client);
      }
      if (result.name == "UnauthorizedException") {
        throw UnauthorizedException(chat.client);
      }
      if (disconnectExceptions.contains(result.name)) {
        throw DisconnectException(chat.client);
      }
      throw result;
    }

    if (result is SuccessResult) {
      return Map<String, String>.from(result.obj as Map);
    }

    throw IncorrectFormatChannelException();
  }

  Future<List<LoginHistoryDTO>> loginHistory(Client client) async {
    var result = await chain("LoginClientChain.getHistory", client: client);

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
      List<dynamic> login = result.obj as List<dynamic>;
      return login
          .map((invite) => Map<String, dynamic>.from(invite as Map))
          .map((map) => LoginHistoryDTO.fromMap(map))
          .toList();
    }

    throw IncorrectFormatChannelException();
  }
}

abstract class Result {}

class ExceptionResult extends Result implements Exception {
  final String name;
  final String? msg;

  ExceptionResult(this.name, [this.msg]);

  @override
  String toString() => "Java - $name: $msg";
}

class SuccessResult extends Result {
  final dynamic obj;
  SuccessResult(this.obj);
}
