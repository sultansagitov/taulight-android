import 'package:flutter/material.dart';
import 'package:taulight/screens/connection.dart';
import 'package:taulight/screens/create_group.dart';
import 'package:taulight/screens/hubs.dart';
import 'package:taulight/screens/key_management.dart';
import 'package:taulight/screens/start_dialog.dart';
import 'package:taulight/services/client.dart';
import 'package:taulight/services/storage.dart';
import 'package:taulight/widget_utils.dart';

enum MainMenu {
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
    action: newGroupAction,
    icon: Icons.add_box_outlined,
  ),
  newDialog(
    text: "Start dialog",
    action: newDialogAction,
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

  const MainMenu({
    required this.text,
    required this.action,
    required this.icon,
  });

  static Future<void> _connectAction(
    BuildContext context,
    VoidCallback callback,
  ) async {
    final screen = ConnectionScreen(connectUpdate: callback);
    final result = await moveTo(context, screen);
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

  static Future<void> newGroupAction(
    BuildContext context,
    VoidCallback callback,
  ) async {
    final result = await moveTo(context, CreateGroupScreen());
    if (result == "success") callback();
  }

  static Future<void> newDialogAction(
    BuildContext context,
    VoidCallback callback,
  ) async {
    final result = await moveTo(context, StartDialogScreen());
    if (result is String) {
      callback();
    }
  }

  static Future<void> _keysAction(
    BuildContext context,
    VoidCallback callback,
  ) async {
    final result = await moveTo(context, KeyManagementScreen());
    if (result is String) {
      callback();
    }
  }

  static Future<void> _clearStorageAction(_, __) async {
    return StorageService.ins.clear();
  }

  static Future<void> _clearMessagesAction(_, VoidCallback callback) async {
    for (final client in ClientService.ins.clientsList) {
      for (final chat in client.chats.values) {
        chat.messages.clear();
      }
    }
    callback();
  }

  static Future<void> _printClientsAction(_, __) async =>
      print("Clients: ${ClientService.ins.clientsList}");
}
