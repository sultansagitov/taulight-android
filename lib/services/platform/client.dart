import 'dart:ui';

import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/nickname.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/classes/uuid.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/client.dart';
import 'package:taulight/services/platform/platform_service.dart';
import 'package:taulight/services/storage.dart';
import 'package:taulight/utils.dart';

final invalidLinkExceptions = [
  "InvalidSandnodeLinkException",
  "CreatingKeyException",
];

class PlatformClientService {
  static final _instance = PlatformClientService._internal();
  static PlatformClientService get ins => _instance;
  PlatformClientService._internal();

  Future<Client> connect(
    String link, {
    VoidCallback? connectUpdate,
    bool keep = false,
  }) async {
    return await connectWithUUID(
      UUID.random(),
      link,
      connectUpdate: connectUpdate,
      keep: keep,
    );
  }

  Future<Client> connectWithUUID(
    UUID uuid,
    String link, {
    VoidCallback? connectUpdate,
    bool keep = false,
  }) async {
    String address;
    try {
      address = link2address(link);
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      throw InvalidSandnodeLinkException(link);
    }

    Client client = Client(uuid: uuid, address: address, link: link);
    client.connecting = true;

    if (keep) ClientService.ins.add(client);
    connectUpdate?.call();

    Result result = await PlatformService.ins.method("connect", {
      "uuid": uuid.toString(),
      "link": link,
    });

    if (result is ExceptionResult) {
      if (invalidLinkExceptions.contains(result.name)) {
        throw InvalidSandnodeLinkException(link);
      }
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      client.connected = true;
      if (!keep) ClientService.ins.add(client);
      await client.resetName();
      connectUpdate?.call();
      return client;
    }
    throw IncorrectFormatChannelException();
  }

  Future<void> reconnect(Client client, [VoidCallback? callback]) async {
    client.connecting = true;
    callback?.call();

    UUID uuid = client.uuid;
    String link = client.link;
    Result result = await PlatformService.ins.method("connect", {
      "uuid": uuid.toString(),
      "link": link,
    });

    callback?.call();

    if (result is ExceptionResult) {
      if (invalidLinkExceptions.contains(result.name)) {
        throw InvalidSandnodeLinkException(link);
      }
      throw result.getCause(client);
    }

    client.connected = true;
    callback?.call();
  }

  Future<String> name(Client client) async {
    final result = await PlatformService.ins.chain(
      "NameClientChain.getName",
      client: client,
    );

    if (result is ExceptionResult) {
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      final obj = result.obj;
      if (obj is String) {
        return obj;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<void> disconnect(Client client) async {
    if (client.connected) {
      Result result = await PlatformService.ins.method("disconnect", {
        "uuid": client.uuid.toString(),
      });

      if (result is ExceptionResult) {
        throw result.getCause(client);
      }
    }
  }

  Future<void> loadClients() async {
    Result result = await PlatformService.ins.method("load-clients");

    if (result is ExceptionResult) {
      throw result.getCause();
    }

    if (result is SuccessResult) {
      final obj = result.obj;
      if (obj is List) {
        for (final map in obj) {
          final uuid = UUID.fromString(map["uuid"]);
          if (ClientService.ins.contains(uuid)) continue;
          final client = ClientService.ins.fromMap(map);
          client.connected = true;

          final String? n = map["nickname"];
          if (n != null) {
            final nickname = Nickname.checked(n);
            final record = await StorageService.ins.getClient(uuid);
            client.user = User(client, nickname, record!.user!.token);
          }

          await client.resetName();
        }
        return;
      }
    }

    throw IncorrectFormatChannelException();
  }
}
