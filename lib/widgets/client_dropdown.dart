import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/client_service.dart';
import 'package:taulight/widgets/chat_avatar.dart';

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
    clients = ClientService.ins.clientsList;

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

          var nickname = user.nickname;
          return ListTile(
            leading: MemberAvatar(client: client, nickname: nickname, d: 44),
            title: Text(nickname),
            subtitle: Text(client.name),
            onTap: () => Navigator.pop(context, client),
          );
        }).toList(),
      ),
    );

    if (client != null) {
      setState(() => widget.controller.setClient(client));
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
