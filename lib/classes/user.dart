import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/nickname.dart';
import 'package:taulight/classes/uuid.dart';
import 'package:taulight/services/platform/agent.dart';

class User {
  Client client;
  UUID? avatarID;
  Nickname nickname;
  String token;
  bool authorized = true;
  bool expiredToken = false;

  User(this.client, this.nickname, this.token);

  factory User.unauthorized(Client client, Nickname nickname, String token) =>
      User(client, nickname, token)..authorized = false;

  Future<void> reloadIfUnauthorized() async {
    if (!authorized) {
      Nickname n = await PlatformAgentService.ins.authByToken(client, token);
      authorized = true;
      if (nickname != n) {
        throw Exception("Nickname mismatch: expected $nickname, got $n");
      }
    }
  }

  @override
  String toString() {
    return "{User $nickname authorized: $authorized}";
  }
}
