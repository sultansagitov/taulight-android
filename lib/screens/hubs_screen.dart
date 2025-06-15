import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/screens/hub_info_screen.dart';
import 'package:taulight/screens/login_screen.dart';
import 'package:taulight/screens/profile_screen.dart';
import 'package:taulight/services/client_service.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/connection_screen.dart';
import 'package:taulight/widgets/chat_avatar.dart';
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

          return _buildHubItem(context, client, connectUpdate);
        },
      ),
    );
  }

  static Widget _buildHubItem(
    BuildContext context,
    Client client,
    VoidCallback connectUpdate,
  ) {
    var status = client.status;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  await moveTo(context, HubInfoScreen(client));
                  connectUpdate();
                },
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
        ),
        if (client.user != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: buildMember(context, client, d: 44, update: connectUpdate),
          ),
      ],
    );
  }

  static Widget buildMember(
    BuildContext context,
    Client client, {
    int? d,
    VoidCallback? update,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await moveTo(context, ProfileScreen(client));
        update?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            MyAvatar(client: client, d: d ?? 52),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                client.user!.nickname,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
