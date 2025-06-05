import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/screens/hub_info_screen.dart';
import 'package:taulight/screens/login_screen.dart';
import 'package:taulight/services/client_service.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/connection_screen.dart';
import 'package:taulight/widgets/hubs_empty.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/widgets/tau_button.dart';

class HubsScreen extends StatefulWidget {
  final VoidCallback? connectUpdate;

  const HubsScreen({super.key, this.connectUpdate});

  @override
  HubsScreenState createState() => HubsScreenState();
}

class HubsScreenState extends State<HubsScreen> {
  void _connectUpdate() {
    setState(() {});
    widget.connectUpdate?.call();
  }

  @override
  Widget build(BuildContext context) {
    var clients = ClientService.ins.clientsList;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Hubs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TauButton.icon(Icons.add, onPressed: () async {
              var screen = ConnectionScreen(connectUpdate: _connectUpdate);
              var result = await moveTo(context, screen);
              if (result != null) {
                setState(() {});
              }
            }),
          ],
        ),
      ),
      body: buildScreen(clients, _connectUpdate),
    );
  }

  static Widget buildScreen(List<Client> clients, VoidCallback connectUpdate) {
    if (clients.isEmpty) return HubsEmpty(connectUpdate: connectUpdate);

    return Container(
      padding: const EdgeInsets.all(8),
      height: 300,
      child: ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) {
          Client client = clients[index];

          var status = client.status;

          return Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => moveTo(context, HubInfoScreen(client)),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            client.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            status.str,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: status.color.withAlpha(192),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (client.hide)
                TauButton.icon(
                  Icons.visibility,
                  onPressed: connectUpdate,
                ),
              if (!client.connected)
                TauButton.icon(
                  Icons.refresh,
                  onPressed: () async {
                    try {
                      await client.reload();
                    } on ConnectionException {
                      if (context.mounted) {
                        snackBarError(
                            context, "Connection error: ${client.name}");
                      }
                    } finally {
                      connectUpdate();
                    }
                  },
                ),
              if (client.connected &&
                  (client.user == null || !client.user!.authorized))
                TauButton.icon(
                  Icons.login,
                  onPressed: () async {
                    var screen = LoginScreen(client: client);
                    var result = await moveTo(context, screen);
                    if (result is String && result.contains("success")) {
                      connectUpdate();
                    }
                  },
                ),
              TauButton.icon(
                Icons.close,
                onPressed: () async {
                  await client.disconnect();
                  await StorageService.ins.removeClient(client);
                  ClientService.ins.remove(client);
                  connectUpdate();
                },
              )
            ],
          );
        },
      ),
    );
  }
}
