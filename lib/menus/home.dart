import 'package:flutter/material.dart';
import 'package:taulight/screens/start_dialog_screen.dart';
import 'package:taulight/screens/connection_screen.dart';
import 'package:taulight/screens/hubs_screen.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/create_channel_screen.dart';

Future<void> showMenuAtHome(
  BuildContext context,
  VoidCallback updateHome,
) async {
  var value = await showMenu(
    context: context,
    position: const RelativeRect.fromLTRB(100, 0, 0, 0),
    items: const [
      PopupMenuItem(value: "connect", child: Text("Connect")),
      PopupMenuItem(value: "connected", child: Text("Show connected hubs")),
      PopupMenuItem(value: "new-channel", child: Text("Create channel")),
      PopupMenuItem(value: "new-dialog", child: Text("Start dialog")),
      PopupMenuItem(value: "clear-storage", child: Text("Clear storage")),
      PopupMenuItem(value: "debug", child: Text("DEBUG")),
    ],
  );

  if (context.mounted && value != null) {
    switch (value) {
      case "connect":
        moveTo(context, ConnectionScreen(updateHome: updateHome));
        break;
      case "connected":
        moveTo(context, HubsScreen(updateHome: updateHome));
        break;
      case "new-channel":
        moveTo(context, CreateChannelScreen(callback: updateHome));
        break;
      case "new-dialog":
        moveTo(context, StartDialogScreen(callback: updateHome));
        break;
      case "clear-storage":
        await StorageService.clear();
        break;
      case "debug":
        print(JavaService.instance.clients);
        break;
    }
  }
}
