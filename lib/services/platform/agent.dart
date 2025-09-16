import 'package:device_info_plus/device_info_plus.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/login_history_dto.dart';
import 'package:taulight/classes/nickname.dart';
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

  Future<String> log(Client client, Nickname nickname, String password) async {
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
      final map = Map<String, String>.from(result.obj);
      final token = map['token']!;
      client.user = User(client, nickname, token);
      UserRecord userRecord = UserRecord(nickname, token);
      await StorageService.ins.saveWithToken(client, userRecord);
      return token;
    }

    throw IncorrectFormatChannelException();
  }

  Future<String> reg(Client client, Nickname nickname, String password) async {
    client.user?.expiredToken = false;

    _device ??= (await DeviceInfoPlugin().deviceInfo).data['name'];

    Result result = await PlatformService.ins.chain(
      "RegistrationClientChain.register",
      client: client,
      params: [nickname, password, _device],
    );

    if (result is ExceptionResult) {
      if (incorrectUserDataExceptions.contains(result.name)) {
        throw IncorrectUserDataException();
      }
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      final map = Map<String, String>.from(result.obj);
      print(map);
      final token = map["token"]!;
      client.user = User(client, nickname, token);
      return token;
    }

    throw IncorrectFormatChannelException();
  }

  Future<Nickname> authByToken(Client client, String token) async {
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
      final obj = Map<String, String>.from(result.obj);
      Nickname nickname = Nickname.checked(obj["nickname"]!.trim());

      final record = UserRecord(nickname, token);
      StorageService.ins.saveWithToken(client, record);
      client.user = User(client, nickname, token);
      return nickname;
    }

    throw IncorrectFormatChannelException();
  }

  Future<void> logout(Client client) async {
    client.user?.expiredToken = false;
    Result result = await PlatformService.ins.chain(
      "LogoutClientChain.logout",
      client: client,
    );

    if (result is ExceptionResult) {
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      StorageService.ins.removeToken(client);
      client.user = null;
      return;
    }

    throw IncorrectFormatChannelException();
  }

  Future<List<LoginHistoryDTO>> loginHistory(Client client) async {
    final result = await PlatformService.ins.method("login-history", {
      "uuid": client.uuid.toString(),
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
