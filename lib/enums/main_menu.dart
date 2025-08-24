import 'package:flutter/material.dart';
import 'package:taulight/services/client.dart';
import 'package:taulight/services/storage.dart';

enum MainMenu {
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
