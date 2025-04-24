import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';

class ClientDropdown extends StatefulWidget {
  final List<Client> clients;
  final Client? initialClient;
  final ValueChanged<Client> onClientChanged;

  const ClientDropdown({
    super.key,
    required this.clients,
    required this.onClientChanged,
    this.initialClient,
  });

  @override
  State<ClientDropdown> createState() => _ClientDropdownState();
}

class _ClientDropdownState extends State<ClientDropdown> {
  Client? selectedClient;

  @override
  void initState() {
    super.initState();
    selectedClient = widget.initialClient ?? widget.clients.elementAtOrNull(0);
    if (selectedClient != null) widget.onClientChanged(selectedClient!);
  }

  void _showClientPicker() async {
    final client = await showModalBottomSheet<Client>(
      context: context,
      builder: (context) => ListView(
        children: widget.clients.map((client) {
          var n = client.user?.nickname.trim().isNotEmpty == true;
          return ListTile(
            title: Text(n ? client.user!.nickname : client.name),
            subtitle: n ? Text(client.name) : null,
            onTap: () => Navigator.pop(context, client),
          );
        }).toList(),
      ),
    );

    if (client != null) {
      setState(() => selectedClient = client);
      widget.onClientChanged(client);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clients.length <= 1) return const SizedBox.shrink();

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
                selectedClient != null
                    ? (selectedClient!.user?.nickname.trim().isNotEmpty == true
                        ? selectedClient!.user!.nickname
                        : selectedClient!.endpoint)
                    : 'Выберите клиента',
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
