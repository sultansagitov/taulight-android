import 'package:flutter/cupertino.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/screens/login_screen.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/tau_button.dart';

class NotLoggedIn extends StatelessWidget {
  final Client client;
  final VoidCallback updateHome;

  const NotLoggedIn(this.client, this.updateHome, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(client.name),
            const SizedBox(height: 10),
            const Text(
              "Not logged in",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            TauButton.text("Login", onPressed: () {
              var screen = LoginScreen(
                client: client,
                updateHome: updateHome,
              );
              moveTo(context, screen);
            }),
          ],
        ),
      ),
    );
  }
}
