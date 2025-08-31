import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/chat_member.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/nickname.dart';
import 'package:taulight/classes/role_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/uuid.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform/platform_service.dart';

class PlatformChatsService {
  static final _instance = PlatformChatsService._internal();
  static PlatformChatsService get ins => _instance;
  PlatformChatsService._internal();

  Future<List<ChatDTO>> loadChats(Client client) async {
    Result result = await PlatformService.ins.method("get-chats", {
      "uuid": client.uuid.toString(),
    });

    if (result is ExceptionResult) {
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      final list = result.obj;
      if (list is List) {
        return list
            .where((obj) => ["gr", "dl"].contains(obj["chat"]["type"]!))
            .map((v) => ChatDTO.fromMap(client, v))
            .toList();
      }
    }
    throw IncorrectFormatChannelException();
  }

  Future<TauChat> loadChat(Client client, UUID id) async {
    final result = await PlatformService.ins.method("load-chat", {
      "uuid": client.uuid.toString(),
      "chat-id": id.toString(),
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

  Future<TauChat> createDialog(Client client, Nickname nickname) async {
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
      final obj = result.obj;
      if (obj is String) {
        return await client.loadChat(UUID.fromString(obj));
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<UUID> createGroup(Client client, String title) async {
    Result result = await PlatformService.ins.chain(
      "GroupClientChain.sendNewGroupRequest",
      client: client,
      params: [title],
    );

    if (result is ExceptionResult) {
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      final obj = result.obj;
      if (obj is String) {
        return UUID.fromString(obj);
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
      final map = Map<String, dynamic>.from(result.obj);
      final rawRoles = map["roles"] as List?;
      final rawMembers = result.obj["members"] as List;

      if (rawRoles != null) {
        for (var rMap in rawRoles) {
          final dto = RoleDTO.fromMap(rMap);
          if (!chat.roles.any((r) => r.id == dto.id)) {
            chat.roles.add(dto);
          }
        }
      }

      return rawMembers.map((m) => ChatMember.fromMap(chat.roles, m)).toList();
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> addMember(
      TauChat chat, Nickname nickname, Duration expirationTime) async {
    final client = chat.client;
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
      final obj = result.obj;
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
