import 'package:taulight/classes/client.dart';

class User {
  Client client;
  String nickname;
  String token;
  bool authorized = true;

  User(this.client, this.nickname, this.token);

  factory User.unauthorized(Client client, String nickname, String token) {
    return User(client, nickname, token)..authorized = false;
  }

  Future<void> reloadIfUnauthorized() async {
    if (!authorized) {
      String nickname = await client.authByToken(token);
      authorized = true;
      if (this.nickname != nickname) {
        throw Exception("Nickname mismatch: "
            "expected ${this.nickname}, got $nickname");
      }
    }
  }

  @override
  String toString() {
    return "{User $nickname authorized: $authorized}";
  }
}
