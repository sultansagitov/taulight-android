import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/java_service.dart';

class ClientDropdown extends StatefulWidget {
  final ClientDropdownController controller;

  const ClientDropdown({super.key, required this.controller});

  @override
  State<ClientDropdown> createState() => _ClientDropdownState();
}

class _ClientDropdownState extends State<ClientDropdown> {
  late final List<Client> clients;

  @override
  void initState() {
    super.initState();
    clients = JavaService.instance.clients.values.toList();

    Client? selectedClient = clients.where((c) => c.authorized).first;
    widget.controller.setClient(selectedClient);
  }

  void _showClientPicker() async {
    final client = await showModalBottomSheet<Client>(
      context: context,
      enableDrag: true,
      showDragHandle: true,
      builder: (context) => ListView(
        children: clients.map((client) {
          var user = client.user;
          if (user == null) {
            return ListTile(
              title: Text("Unauthorized"),
              subtitle: Text(client.name),
            );
          }

          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              // TODO replace to avatar
              child: Container(
                color: Colors.black,
                width: 44,
                height: 44,
              ),
            ),
            title: Text(user.nickname),
            subtitle: Text(client.name),
            onTap: () => Navigator.pop(context, client),
          );
        }).toList(),
      ),
    );

    if (client != null) {
      widget.controller.setClient(client);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (clients.length <= 1) return const SizedBox.shrink();

    var client = widget.controller.client;
    var data = client != null
        ? (client.user != null ? client.user!.nickname : "Incorrect hub")
        : 'No hubs';
    return GestureDetector(
      onTap: _showClientPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                data,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class ClientDropdownController extends ChangeNotifier {
  Client? _currentClient;

  Client? get client => _currentClient;

  void setClient(Client client) {
    _currentClient = client;
    notifyListeners();
  }
}
