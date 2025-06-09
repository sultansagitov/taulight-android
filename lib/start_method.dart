import 'package:flutter/cupertino.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/method_call_handler.dart';
import 'package:taulight/services/client_service.dart';
import 'package:taulight/services/platform_service.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/widget_utils.dart';

Future<void> start(
  BuildContext context,
  MethodCallHandler methodCallHandler,
  VoidCallback callback,
) async {
  await PlatformService.ins.loadClients();

  Map<String, ServerRecord> map = await StorageService.ins.getClients();

  Set<String> connectedSet = ClientService.ins.keys;
  Set<String> storageSet = map.keys.toSet();

  Set<String> notConnectedId = storageSet.difference(connectedSet);

  for (String uuid in notConnectedId) {
    ServerRecord sr = map[uuid]!;
    try {
      await PlatformService.ins.connectWithUUID(uuid, sr.link, keep: true);
    } on ConnectionException {
      if (context.mounted) {
        snackBarError(context, "Connection error: ${sr.name}");
      }
    } finally {
      Client? c = ClientService.ins.get(uuid);
      if (c != null) {
        UserRecord? userRecord = sr.user;
        if (userRecord != null) {
          String nickname = userRecord.nickname.trim();
          String keyID = userRecord.keyID;
          String token = userRecord.token;
          c.user = User.unauthorized(c, nickname, keyID, token);
        }
      }
    }
  }

  for (var client in ClientService.ins.clientsList) {
    if (!client.connected) continue;

    if (client.user == null || !client.user!.authorized) {
      ServerRecord? serverRecord = map[client.uuid];
      if (serverRecord != null && serverRecord.user != null) {
        String? error;

        try {
          await client.authByToken(serverRecord.user!.token, store: false);
        } on ExpiredTokenException {
          error = "Session expired. ${client.name}";
        } on InvalidArgumentException {
          error = "Invalid token. ${client.name}";
        }

        if (error != null) {
          if (context.mounted) snackBarError(context, error);
          await StorageService.ins.removeToken(client);
        }
      }
    }
  }

  await TauChat.loadAll(callback: callback);
}
