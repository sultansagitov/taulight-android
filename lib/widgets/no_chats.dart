import 'package:flutter/cupertino.dart';
import 'package:taulight/screens/create_channel_screen.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/tau_button.dart';

class NoChats extends StatelessWidget {
  final VoidCallback updateHome;

  const NoChats(this.updateHome, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("No chats", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            TauButton.text("Create channel", onPressed: () {
              moveTo(context, CreateChannelScreen(callback: updateHome));
            }),
          ],
        ),
      ),
    );
  }
}
