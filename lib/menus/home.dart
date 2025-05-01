import 'package:flutter/material.dart';
import 'package:taulight/screens/start_dialog_screen.dart';
import 'package:taulight/screens/connection_screen.dart';
import 'package:taulight/screens/hubs_screen.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/create_channel_screen.dart';

enum MenuOption {
  connect(
    text: "Connect",
    action: _connectAction,
    icon: Icons.link,
  ),
  connected(
    text: "Show connected hubs",
    action: _connectedAction,
    icon: Icons.device_hub,
  ),
  newChannel(
    text: "Create channel",
    action: _newChannelAction,
    icon: Icons.add_box,
  ),
  newDialog(
    text: "Start dialog",
    action: _newDialogAction,
    icon: Icons.chat,
  ),
  clearStorage(
    text: "CLEAR STORAGE",
    action: _clearStorageAction,
    icon: Icons.bug_report,
  ),
  clearMessages(
    text: "CLEAR ALL MESSAGES",
    action: _clearMessagesAction,
    icon: Icons.bug_report,
  ),
  printClients(
    text: "PRINT CLIENTS",
    action: _printClientsAction,
    icon: Icons.bug_report,
  );

  final String text;
  final void Function(BuildContext, VoidCallback) action;
  final IconData icon;

  const MenuOption(
      {required this.text, required this.action, required this.icon});

  static void _connectAction(BuildContext context, VoidCallback callback) =>
      moveTo(context, ConnectionScreen(updateHome: callback));

  static void _connectedAction(BuildContext context, VoidCallback callback) =>
      moveTo(context, HubsScreen(updateHome: callback));

  static void _newChannelAction(BuildContext context, VoidCallback callback) =>
      moveTo(context, CreateChannelScreen(callback: callback));

  static void _newDialogAction(BuildContext context, VoidCallback callback) =>
      moveTo(context, StartDialogScreen(callback: callback));

  static void _clearStorageAction(_, __) => StorageService.clear();

  static void _clearMessagesAction(_, VoidCallback callback) {
    for (var client in JavaService.instance.clients.values) {
      for (var chat in client.chats.values) {
        chat.messages.clear();
      }
    }
    callback();
  }

  static void _printClientsAction(_, __) =>
      print("Clients: ${JavaService.instance.clients}");
}

Future<void> showMenuAtHome(BuildContext context, VoidCallback callback) async {
  var value = await showMenu<MenuOption>(
    context: context,
    position: const RelativeRect.fromLTRB(100, 0, 0, 0),
    items: MenuOption.values.map((o) {
      return PopupMenuItem<MenuOption>(
        value: o,
        child: Row(children: [Icon(o.icon), SizedBox(width: 8), Text(o.text)]),
      );
    }).toList(),
  );

  if (context.mounted) value?.action(context, callback);
}
