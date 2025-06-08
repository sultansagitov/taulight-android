import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/filter.dart';

class ClientService {
  static final ClientService _instance = ClientService._internal();
  static ClientService get ins => _instance;
  ClientService._internal();

  FilterManager filterManager = FilterManager();

  final Map<String, Client> _clients = {};

  Set<String> get keys => _clients.keys.toSet();
  List<Client> get clientsList => _clients.values.toList();

  Client? get(String uuid) => _clients[uuid];
  bool contains(uuid) => _clients.containsKey(uuid);
  void add(Client client) {
    if (_clients.containsKey(client.uuid)) {
      throw Exception("Busy uuid : $client");
    }
    _clients[client.uuid] = client;

    client.filter = AnyFilter(
      ClientService.ins.filterManager,
      () => (client.authorized)
          ? "${client.name} (${client.user!.nickname})"
          : client.name,
      (chat) => chat.client == client,
    );
  }

  void remove(Client client) => _clients.remove(client.uuid);

  Client fromMap(map) {
    var client = Client(
      uuid: map['uuid'],
      address: map['address'],
      link: map['link'],
    );

    add(client);

    return client;
  }
}
