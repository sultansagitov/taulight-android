import 'package:taulight/classes/client.dart';

class User {
  Client client;
  String nickname;
  String token;
  bool authorized = true;
  bool expiredToken = false;

  User(this.client, this.nickname, this.token);

  factory User.unauthorized(Client client, String nickname, String token) {
    return User(client, nickname, token)..authorized = false;
  }

  Future<void> reloadIfUnauthorized() async {
    if (!authorized) {
      String n = await client.authByToken(token);
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
