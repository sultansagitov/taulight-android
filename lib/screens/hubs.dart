import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/screens/hub_info.dart';
import 'package:taulight/screens/login.dart';
import 'package:taulight/screens/profile.dart';
import 'package:taulight/services/client.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/connection.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/hubs_empty.dart';
import 'package:taulight/services/storage.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
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
      appBar: TauAppBar.text("Hubs", actions: [
        TauButton.icon(Icons.add, onPressed: () async {
          var screen = ConnectionScreen(connectUpdate: _connectUpdate);
          var result = await moveTo(context, screen);
          if (result != null) setState(() {});
        }),
      ]),
      body: buildScreen(context, clients, _connectUpdate),
    );
  }

  static Widget buildScreen(
      BuildContext context, List<Client> clients, VoidCallback connectUpdate) {
    if (clients.isEmpty) return HubsEmpty(connectUpdate: connectUpdate);

    return Container(
      padding: const EdgeInsets.all(8),
      child: ListView(
          children: clients
              .map((client) => _buildHubItem(context, client, connectUpdate))
              .toList()),
    );
  }

  static Widget _buildHubItem(
    BuildContext context,
    Client client,
    VoidCallback connectUpdate,
  ) {
    final status = client.status;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    child: Card(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status.str,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: status.color.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (client.user != null) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          await moveTo(context, ProfileScreen(client));
                          connectUpdate();
                        },
                        child: MyAvatar(client: client, d: 44),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: TauButton.icon(
                    client.hide ? Icons.visibility : Icons.visibility_off,
                    disable: client.connected,
                    onPressed: () {
                      client.hide = !client.hide;
                      connectUpdate();
                    },
                  ),
                ),
                Expanded(
                  child: TauButton.icon(
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
                ),
                Expanded(
                  child: TauButton.icon(
                    Icons.login,
                    disable: !(client.connected &&
                        (client.user == null || !client.user!.authorized)),
                    onPressed: () async {
                      final result =
                          await moveTo(context, LoginScreen(client: client));
                      if (result is String && result.contains("success")) {
                        connectUpdate();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: TauButton.icon(
                    Icons.close,
                    onPressed: () async {
                      await client.disconnect();
                      await StorageService.ins.removeClient(client);
                      ClientService.ins.remove(client);
                      connectUpdate();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
