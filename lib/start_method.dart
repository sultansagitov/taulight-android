import 'package:flutter/cupertino.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/method_call_handler.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/widget_utils.dart';

void start({
  required BuildContext context,
  required MethodCallHandler methodCallHandler,
  required VoidCallback update,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await JavaService.instance.loadClients();

    Map<String, ServerRecord> map = await StorageService.getClients();

    Set<String> connectedSet = JavaService.instance.clients.keys.toSet();
    Set<String> storageSet = map.keys.toSet();

    Set<String> notConnectedId = storageSet.difference(connectedSet);

    for (String uuid in notConnectedId) {
      ServerRecord sr = map[uuid]!;
      try {
        await JavaService.instance.connectWithUUID(uuid, sr.link);
        Client c = JavaService.instance.clients[uuid]!;
        UserRecord? userRecord = sr.user;
        if (userRecord != null) {
          String nickname = userRecord.nickname;
          String token = userRecord.token;
          c.user = User.unauthorized(c, nickname, token);
        }
      } on ConnectionException {
        if (context.mounted) {
          snackBar(context, "Connection error: ${sr.name}");
        }
      }
    }

    for (var client in JavaService.instance.clients.values) {
      if (!client.connected) continue;

      if (client.user == null || !client.user!.authorized) {
        ServerRecord? serverRecord = map[client.uuid];
        if (serverRecord != null && serverRecord.user != null) {
          try {
            var token = serverRecord.user!.token;
            var nickname = await client.authByToken(token);
            client.user = User(client, nickname, token);
          } on ExpiredTokenException {
            if (context.mounted) {
              snackBar(context, "Session expired. ${client.name}");
            }
            await StorageService.removeToken(client);
          } on InvalidTokenException {
            if (context.mounted) {
              snackBar(context, "Invalid token. ${client.name}");
            }
            await StorageService.removeToken(client);
          }
        }
      }
    }

    await TauChat.loadAll();
    update();
  });
}
