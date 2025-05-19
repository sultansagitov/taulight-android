import 'package:taulight/classes/client.dart';

class ClientService {
  static final ClientService _instance = ClientService._internal();
  static ClientService get ins => _instance;
  ClientService._internal();

  final Map<String, Client> _clients = {};

  Set<String> get keys => _clients.keys.toSet();
  List<Client> get clientsList => _clients.values.toList();

  Client? get(String uuid) => _clients[uuid];
  bool contains(uuid) => _clients.containsKey(uuid);
  void add(Client client) => _clients[client.uuid] = client;
  void remove(Client client) => _clients.remove(client.uuid);

  Client fromMap(map) {
    var client = Client(
      uuid: map['uuid'],
      endpoint: map['endpoint'],
      link: map['link'],
    );

    add(client);

    return client;
  }
}
