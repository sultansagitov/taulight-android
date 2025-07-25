import 'package:flutter/material.dart';
import 'package:taulight/screens/connection_screen.dart';
import 'package:taulight/screens/create_group_screen.dart';
import 'package:taulight/screens/hubs_screen.dart';
import 'package:taulight/screens/key_management_screen.dart';
import 'package:taulight/screens/start_dialog_screen.dart';
import 'package:taulight/services/client_service.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

enum MenuOption {
  connect(
    text: "Connect",
    action: _connectAction,
    icon: Icons.link_outlined,
  ),
  connected(
    text: "Show hubs and profile",
    action: _hubsAction,
    icon: Icons.person_outlined,
  ),
  newGroup(
    text: "Create group",
    action: _newGroupAction,
    icon: Icons.add_box_outlined,
  ),
  newDialog(
    text: "Start dialog",
    action: _newDialogAction,
    icon: Icons.chat_outlined,
  ),
  keys(
    text: "Keys",
    action: _keysAction,
    icon: Icons.key_outlined,
  ),
  clearStorage(
    text: "CLEAR STORAGE",
    action: _clearStorageAction,
    icon: Icons.bug_report_outlined,
  ),
  clearMessages(
    text: "CLEAR ALL MESSAGES",
    action: _clearMessagesAction,
    icon: Icons.bug_report_outlined,
  ),
  printClients(
    text: "PRINT CLIENTS",
    action: _printClientsAction,
    icon: Icons.bug_report_outlined,
  );

  final String text;
  final Future<void> Function(BuildContext, VoidCallback) action;
  final IconData icon;

  const MenuOption({
    required this.text,
    required this.action,
    required this.icon,
  });

  static Future<void> _connectAction(
      BuildContext context,
      VoidCallback callback,
      ) async {
    var screen = ConnectionScreen(connectUpdate: callback);
    var result = await moveTo(context, screen);
    if (result != null) {
      callback();
    }
  }

  static Future<void> _hubsAction(
      BuildContext context,
      VoidCallback callback,
      ) async {
    await moveTo(context, HubsScreen(connectUpdate: callback));
    callback();
  }

  static Future<void> _newGroupAction(
      BuildContext context,
      VoidCallback callback,
      ) async {
    var result = await moveTo(context, CreateGroupScreen());
    if (result == "success") callback();
  }

  static Future<void> _newDialogAction(
      BuildContext context,
      VoidCallback callback,
      ) async {
    var result = await moveTo(context, StartDialogScreen());
    if (result is String) {
      callback();
    }
  }

  static Future<void> _keysAction(
      BuildContext context,
      VoidCallback callback,
      ) async {
    var result = await moveTo(context, KeyManagementScreen());
    if (result is String) {
      callback();
    }
  }

  static Future<void> _clearStorageAction(_, __) async {
    return StorageService.ins.clear();
  }

  static Future<void> _clearMessagesAction(_, VoidCallback callback) async {
    for (var client in ClientService.ins.clientsList) {
      for (var chat in client.chats.values) {
        chat.messages.clear();
      }
    }
    callback();
  }

  static Future<void> _printClientsAction(_, __) async =>
      print("Clients: ${ClientService.ins.clientsList}");
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TauAppBar.text("Taulight"),
      body: ListView(
        children: MenuOption.values.map((option) {
          return ListTile(
            leading: Icon(option.icon),
            title: Text(option.text),
            onTap: () => option.action(context, () => setState(() {})),
          );
        }).toList(),
      ),
    );
  }
}