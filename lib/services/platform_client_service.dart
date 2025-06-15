import 'dart:ui';

import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/client_service.dart';
import 'package:taulight/services/platform_service.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/utils.dart';
import 'package:uuid/uuid.dart';

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
    String uuid = Uuid().v4();
    return await connectWithUUID(
      uuid,
      link,
      connectUpdate: connectUpdate,
      keep: keep,
    );
  }

  Future<Client> connectWithUUID(
    String uuid,
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

    // TODO add connecting status

    Client client = Client(uuid: uuid, address: address, link: link);

    if (keep) ClientService.ins.add(client);
    connectUpdate?.call();

    Result result = await PlatformService.ins.method("connect", {
      "uuid": uuid,
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
    String uuid = client.uuid;
    String link = client.link;
    Result result = await PlatformService.ins.method("connect", {
      "uuid": uuid,
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
    var result = await PlatformService.ins.chain(
      "NameClientChain.getName",
      client: client,
    );

    if (result is ExceptionResult) {
      throw result.getCause(client);
    }

    if (result is SuccessResult) {
      var obj = result.obj;
      if (obj is String) {
        return obj;
      }
    }

    throw IncorrectFormatChannelException();
  }

  Future<void> disconnect(Client client) async {
    if (client.connected) {
      Result result = await PlatformService.ins.method("disconnect", {
        "uuid": client.uuid,
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
      ClientService clientService = ClientService.ins;

      var obj = result.obj;
      if (obj is List) {
        for (var map in obj) {
          String uuid = map["uuid"];
          if (clientService.contains(uuid)) continue;
          Client client = clientService.fromMap(map);
          client.connected = true;

          if (map["nickname"] != null) {
            var record = await StorageService.ins.getClient(uuid);
            client.user = User(client, map["nickname"], record!.user!.token,
                record.user!.keyID);
          }

          await client.resetName();
        }
        return;
      }
    }

    throw IncorrectFormatChannelException();
  }
}
