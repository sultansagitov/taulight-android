import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/code_dto.dart';
import 'package:taulight/services/platform/codes.dart';

class InviteService {
  static final InviteService _instance = InviteService._internal();
  static InviteService get ins => _instance;
  InviteService._internal();

  Map<String, Map<String, CodeDTO>> codes = {};

  String? extractInviteCode(String url) {
    final RegExp inviteRegExp = RegExp(r'invite/([a-zA-Z0-9]+)');
    final match = inviteRegExp.firstMatch(url);
    return match?.group(1);
  }

  Future<CodeDTO> checkCode(Client client, String codeString) async {
    codes[client.uuid] ??= {};
    codes[client.uuid]![codeString] ??=
        await PlatformCodesService.ins.checkCode(client, codeString);
    return codes[client.uuid]![codeString]!;
  }
}
