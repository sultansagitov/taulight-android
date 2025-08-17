import 'package:flutter/cupertino.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/screens/login.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/flat_rect_button.dart';

class NotLoggedIn extends StatelessWidget {
  final Client client;
  final Future<void> Function(dynamic)? onLogin;

  const NotLoggedIn(this.client, {super.key, this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(client.name),
          const SizedBox(height: 10),
          const Text("Not logged in", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          FlatRectButton(label: "Login", onPressed: () async {
            final screen = LoginScreen(
              client: client,
              nickname: client.user?.nickname,
            );
            final result = await moveTo(context, screen);
            await onLogin?.call(result);
          }),
        ],
      ),
    );
  }
}
