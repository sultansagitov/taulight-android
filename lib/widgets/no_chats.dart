import 'package:flutter/cupertino.dart';
import 'package:taulight/dialogs/channel_dialog.dart';
import 'package:taulight/widgets/tau_buton.dart';

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
            TauButton("Create channel", onPressed: () {
              channelDialog(context, updateHome);
            }),
          ],
        ),
      ),
    );
  }
}
