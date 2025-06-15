import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/code_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform_service.dart';

class PlatformCodesService {
  static final _instance = PlatformCodesService._internal();
  static PlatformCodesService get ins => _instance;
  PlatformCodesService._internal();

  Future<List<Map<String, dynamic>>> getGroupCodes(
    Client client,
    TauChat chat,
  ) async {
    Result result = await PlatformService.ins.chain(
      "GroupClientChain.getGroupCodes",
      client: client,
      params: [chat.record.id],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(client);
      }
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      List<dynamic> invites = result.obj as List<dynamic>;
      return invites
          .map((invite) => Map<String, dynamic>.from(invite as Map))
          .toList();
    }

    throw IncorrectFormatChannelException();
  }

  Future<CodeDTO> checkCode(Client client, String code) async {
    Result result = await PlatformService.ins.chain(
      "CheckCodeClientChain.check",
      client: client,
      params: [code],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw NotFoundException(client, code);
      }
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      return CodeDTO.fromMap(result.obj);
    }

    throw IncorrectFormatChannelException();
  }

  Future<void> useCode(Client client, String code) async {
    Result result = await PlatformService.ins.chain(
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
      throw result.getCause(client);
    }
  }
}
