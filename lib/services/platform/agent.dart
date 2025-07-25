import 'package:device_info_plus/device_info_plus.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/login_history_dto.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform/platform_service.dart';
import 'package:taulight/services/storage.dart';

final incorrectUserDataExceptions = [
  "UnauthorizedException",
  "MemberNotFoundException",
];

class PlatformAgentService {
  static final _instance = PlatformAgentService._internal();
  static PlatformAgentService get ins => _instance;
  PlatformAgentService._internal();

  String? _device;

  Future<String> log(Client client, String nickname, String password) async {
    client.user?.expiredToken = false;

    _device ??= (await DeviceInfoPlugin().deviceInfo).data['name'];

    Result result = await PlatformService.ins.chain(
      "LogPasswdClientChain.getToken",
      client: client,
      params: [nickname, password, _device!],
    );
    if (result is ExceptionResult) {
      if (incorrectUserDataExceptions.contains(result.name)) {
        throw IncorrectUserDataException();
      }

      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      var map = Map<String, String>.from(result.obj);
      var token = map['token']!;
      String keyID = map['key-id']!;
      client.user = User(client, nickname, keyID, token);
      UserRecord userRecord = UserRecord(nickname, token, keyID);
      await StorageService.ins.saveWithToken(client, userRecord);
      return token;
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> reg(Client client, String nickname, String password) async {
    client.user?.expiredToken = false;

    _device ??= (await DeviceInfoPlugin().deviceInfo).data['name'];

    Result result = await PlatformService.ins.method("register", {
      "uuid": client.uuid,
      "nickname": nickname,
      "password": password,
      "device": _device!,
    });

    if (result is ExceptionResult) {
      if (incorrectUserDataExceptions.contains(result.name)) {
        throw IncorrectUserDataException();
      }
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      var map = Map<String, String>.from(result.obj);
      print(map);
      var token = map["token"]!;
      var keyID = map["key-id"]!;
      client.user = User(client, nickname, keyID, token);
      return token;
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> authByToken(Client client, String token) async {
    client.user?.expiredToken = false;
    Result result = await PlatformService.ins.chain(
      "LoginClientChain.login",
      client: client,
      params: [token],
    );

    if (result is ExceptionResult) {
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      var obj = Map<String, String>.from(result.obj);
      String nickname = obj["nickname"]!.trim();
      String keyID = obj["key-id"]!.trim();

      var record = UserRecord(nickname, token, keyID);
      StorageService.ins.saveWithToken(client, record);
      client.user = User(client, nickname, keyID, token);
      return nickname;
    }

    throw IncorrectFormatChannelException();
  }

  Future<List<LoginHistoryDTO>> loginHistory(Client client) async {
    var result = await PlatformService.ins.method("login-history", {
      "uuid": client.uuid,
    });

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(client);
      }
      throw result.getCause(client);
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
