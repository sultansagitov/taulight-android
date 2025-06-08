import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform_service.dart';

class PlatformAvatarService {
  static final PlatformAvatarService _instance =
      PlatformAvatarService._internal();
  static PlatformAvatarService get ins => _instance;
  PlatformAvatarService._internal();

  Future<String> setGroupAvatar(TauChat chat, String imagePath) async {
    var result = await PlatformService.ins.chain(
      "GroupClientChain.setAvatar",
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

    if (result is SuccessResult) {
      var avatarID = result.obj;
      if (avatarID is String) {
        return avatarID;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<Map<String, String>?> getGroupAvatar(TauChat chat) async {
    Result result = await PlatformService.ins.chain(
      "GroupClientChain.getAvatar",
      client: chat.client,
      params: [chat.record.id],
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

    if (result is SuccessResult) {
      return result.obj != null
          ? Map<String, String>.from(result.obj as Map)
          : null;
    }

    throw IncorrectFormatChannelException();
  }

  Future<Map<String, String>?> getDialogAvatar(TauChat chat) async {
    Result result = await PlatformService.ins.chain(
      "DialogClientChain.getAvatar",
      client: chat.client,
      params: [chat.record.id],
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

    if (result is SuccessResult) {
      return result.obj != null
          ? Map<String, String>.from(result.obj as Map)
          : null;
    }

    throw IncorrectFormatChannelException();
  }

  Future<Map<String, String>?> getMy(Client client) async {
    var result = await PlatformService.ins.chain(
      "AvatarClientChain.getMy",
      client: client,
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
      return result.obj != null
          ? Map<String, String>.from(result.obj as Map)
          : null;
    }

    throw IncorrectFormatChannelException();
  }

  Future<Map<String, String>?> getOf(Client client, String nickname) async {
    var result = await PlatformService.ins.chain(
      "AvatarClientChain.getOf",
      client: client,
      params: [nickname],
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
      return result.obj != null
          ? Map<String, String>.from(result.obj as Map)
          : null;
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> setMy(Client client, String path) async {
    var result = await PlatformService.ins.chain(
      "AvatarClientChain.set",
      client: client,
      params: [path],
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
      var id = result.obj;
      if (id is String) {
        return id;
      }
    }

    throw IncorrectFormatChannelException();
  }
}
