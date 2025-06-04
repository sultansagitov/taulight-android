import 'package:flutter/cupertino.dart';
import 'package:taulight/screens/create_group_screen.dart';
import 'package:taulight/screens/start_dialog_screen.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/tau_button.dart';

class NoChats extends StatelessWidget {
  final VoidCallback updateHome;

  const NoChats({super.key, required this.updateHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("No chats", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          TauButton.text("Create group", onPressed: () async {
            var result = await moveTo(context, CreateGroupScreen());
            if (result is String && result.contains("success")) {
              updateHome();
            }
          }),
          const SizedBox(height: 10),
          TauButton.text("Start dialog", onPressed: () async {
            var result = await moveTo(context, StartDialogScreen());
            if (result is String && result.contains("success")) {
              updateHome();
            }
          }),
        ],
      ),
    );
  }
}
