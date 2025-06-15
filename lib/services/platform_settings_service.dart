import 'dart:async';

import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_member_settings_response_dto.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform_service.dart';

class PlatformSettingsService {
  static final _instance = PlatformSettingsService._internal();
  static PlatformSettingsService get ins => _instance;
  PlatformSettingsService._internal();

  Future<TauMemberSettingsResponseDTO> get(Client client) async {
    var result = await PlatformService.ins.chain(
      "TauMemberSettingsClientChain.get",
      client: client,
    );

    if (result is ExceptionResult) {
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      return TauMemberSettingsResponseDTO.fromMap(result.obj);
    }

    throw IncorrectFormatChannelException();
  }

  Future<void> setShowStatus(Client client, bool value) async {
    var result = await PlatformService.ins.chain(
      "TauMemberSettingsClientChain.setShowStatus",
      client: client,
      params: [value],
    );

    if (result is ExceptionResult) {
      throw result.getCause(client);
    }
  }
}
