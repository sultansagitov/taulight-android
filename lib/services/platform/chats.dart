import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/chat_member.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/role_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform/platform_service.dart';

class PlatformChatsService {
  static final _instance = PlatformChatsService._internal();
  static PlatformChatsService get ins => _instance;
  PlatformChatsService._internal();

  Future<List<ChatDTO>> loadChats(Client client) async {
    Result result = await PlatformService.ins.method("get-chats", {
      "uuid": client.uuid,
    });

    if (result is ExceptionResult) {
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      var list = result.obj;
      if (list is List) {
        return list
            .where((obj) => ["gr", "dl"].contains(obj["chat"]["type"]!))
            .map((v) => ChatDTO.fromMap(client, v))
            .toList();
      }
    }
    throw IncorrectFormatChannelException();
  }

  Future<TauChat> loadChat(Client client, String id) async {
    var result = await PlatformService.ins.method("load-chat", {
      "uuid": client.uuid,
      "chat-id": id,
    });

    if (result is ExceptionResult) {
      if (result.name == "ChatNotFoundException") {
        throw ChatNotFoundException(client);
      }
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      return TauChat(client, ChatDTO.fromMap(client, result.obj));
    }

    throw IncorrectFormatChannelException();
  }

  Future<TauChat> createDialog(Client client, String nickname) async {
    Result result = await PlatformService.ins.chain(
      "DialogClientChain.getDialogID",
      client: client,
      params: [nickname],
    );

    if (result is ExceptionResult) {
      if (result.name == "AddressedMemberNotFoundException") {
        throw AddressedMemberNotFoundException(client, nickname);
      }
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is String) {
        return await client.loadChat(obj);
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> createGroup(Client client, String title) async {
    Result result = await PlatformService.ins.chain(
      "GroupClientChain.sendNewGroupRequest",
      client: client,
      params: [title],
    );

    if (result is ExceptionResult) {
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is String) {
        return obj;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<List<ChatMember>> getMembers(TauChat chat) async {
    Result result = await PlatformService.ins.chain(
      "MembersClientChain.getMembers",
      client: chat.client,
      params: [chat.record.id],
    );

    if (result is ExceptionResult) {
      throw result.getCause(chat.client);
    }

    if (result is SuccessResult) {
      var map = Map<String, dynamic>.from(result.obj);
      if (map["roles"] != null) {
        for (var rMap in map["roles"]) {
          if (!chat.roles.any((r) => r.id == rMap["id"])) {
            chat.roles.add(RoleDTO.fromMap(rMap));
          }
        }
      }

      var members = result.obj["members"];
      return members
          .map<ChatMember>((m) => ChatMember.fromMap(chat.roles, m))
          .toList();
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> addMember(
      TauChat chat, String nickname, Duration expirationTime) async {
    var client = chat.client;
    Result result = await PlatformService.ins.chain(
      "GroupClientChain.createInviteCode",
      client: client,
      params: [chat.record.id, nickname, expirationTime.inSeconds.toString()],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw NotFoundException(client, chat);
      }
      if (result.name == "AddressedMemberNotFoundException") {
        throw AddressedMemberNotFoundException(client, nickname);
      }
      if (result.name == "NoEffectException") {
        throw NoEffectException(nickname);
      }
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is String) {
        return obj;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<void> leaveChat(TauChat chat) async {
    Result result = await PlatformService.ins.chain(
      "GroupClientChain.sendLeaveRequest",
      client: chat.client,
      params: [chat.record.id],
    );

    if (result is ExceptionResult) {
      throw result.getCause(chat.client);
    }
  }
}
