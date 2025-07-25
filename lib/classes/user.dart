import 'package:taulight/classes/client.dart';
import 'package:taulight/services/platform/agent.dart';

class User {
  Client client;
  String keyID;
  String? avatarID;
  String nickname;
  String token;
  bool authorized = true;
  bool expiredToken = false;

  User(this.client, this.nickname, this.keyID, this.token);

  factory User.unauthorized(
          Client client, String nickname, String keyID, String token) =>
      User(client, nickname, keyID, token)..authorized = false;

  Future<void> reloadIfUnauthorized() async {
    if (!authorized) {
      String n = await PlatformAgentService.ins.authByToken(client, token);
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
