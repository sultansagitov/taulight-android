import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform_service.dart';

class PlatformAvatarService {
  static final PlatformAvatarService _instance =
      PlatformAvatarService._internal();
  static PlatformAvatarService get ins => _instance;
  PlatformAvatarService._internal();

  Future<Map<String, String>> getAvatar(Client client) async {
    var result =
        await PlatformService.ins.method("get-avatar", {"uuid": client.uuid});

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
