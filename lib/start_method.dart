import 'package:flutter/cupertino.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/method_call_handler.dart';
import 'package:taulight/services/client.dart';
import 'package:taulight/services/platform/agent.dart';
import 'package:taulight/services/platform/client.dart';
import 'package:taulight/services/storage.dart';
import 'package:taulight/widget_utils.dart';

Future<void> start(
  BuildContext context,
  MethodCallHandler methodCallHandler,
  VoidCallback callback,
) async {
  await PlatformClientService.ins.loadClients();
  final map = await StorageService.ins.getClients();

  final notConnected = map.keys.toSet().difference(ClientService.ins.keys);

  for (final uuid in notConnected) {
    final sr = map[uuid]!;
    try {
      final link = sr.link;
      await PlatformClientService.ins.connectWithUUID(uuid, link, keep: true);
    } on ConnectionException {
      if (context.mounted) {
        snackBarError(context, "Connection error: ${sr.name}");
      }
    } finally {
      final client = ClientService.ins.get(uuid);
      final user = sr.user;
      if (client != null && user != null) {
        final nickname = user.nickname.trim();
        client.user = User.unauthorized(client, nickname, user.token);
      }
    }
  }

  final clients = ClientService.ins.clientsList.where((c) => c.connected);
  for (final client in clients) {
    final user = client.user;
    if (user != null && user.authorized) continue;

    final sr = map[client.uuid];
    if (sr?.user == null) continue;

    try {
      await PlatformAgentService.ins.authByToken(client, sr!.user!.token);
    } on ExpiredTokenException {
      if (context.mounted) {
        snackBarError(context, "Session expired. ${client.name}");
      }
    } on InvalidArgumentException {
      if (context.mounted) {
        snackBarError(context, "Invalid token. ${client.name}");
      }
    }
  }

  await TauChat.loadAll(callback: callback);
}
