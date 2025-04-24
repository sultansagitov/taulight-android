import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/dialogs/hub_dialog.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/screens/login.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/connection_screen.dart';
import 'package:taulight/widgets/hubs_empty.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/services/storage_service.dart';

class HubsScreen extends StatefulWidget {
  final VoidCallback? updateHome;

  const HubsScreen({super.key, this.updateHome});

  @override
  HubsScreenState createState() => HubsScreenState();
}

class HubsScreenState extends State<HubsScreen> {
  @override
  Widget build(BuildContext context) {
    var clients = JavaService.instance.clients.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Hubs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                moveTo(context, ConnectionScreen(updateHome: _updateHome));
              },
            ),
          ],
        ),
      ),
      body: buildScreen(clients, _updateHome),
    );
  }

  void _updateHome() {
    setState(() {});
    widget.updateHome?.call();
  }

  static Widget buildScreen(List<Client> clients, VoidCallback updateHome) {
    if (clients.isEmpty) return HubsEmpty(updateHome: updateHome);

    return Container(
      padding: const EdgeInsets.all(8),
      height: 300,
      child: ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) {
          Client client = clients[index];

          var buttonStyle = ButtonStyle(
            padding: WidgetStateProperty.all(
              EdgeInsets.symmetric(horizontal: 8),
            ),
            minimumSize: WidgetStateProperty.all(Size.zero),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );

          return Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => openHubDialog(context, client),
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
                            client.status,
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (client.hide)
                IconButton(
                  style: buttonStyle,
                  icon: Icon(Icons.visibility),
                  onPressed: updateHome,
                ),
              if (!client.connected)
                IconButton(
                  style: buttonStyle,
                  icon: Icon(Icons.refresh),
                  onPressed: () async {
                    try {
                      await client.reload();
                    } on ConnectionException {
                      if (context.mounted) {
                        snackBar(context, "Connection error: ${client.name}");
                      }
                    } finally {
                      updateHome();
                    }
                  },
                ),
              if (client.connected &&
                  (client.user == null || !client.user!.authorized))
                IconButton(
                  style: buttonStyle,
                  icon: Icon(Icons.login),
                  onPressed: () {
                    LoginScreen screen = LoginScreen(
                      client: client,
                      updateHome: updateHome,
                    );
                    moveTo(context, screen);
                  },
                ),
              IconButton(
                style: buttonStyle,
                icon: Icon(Icons.close),
                onPressed: () async {
                  await client.disconnect();
                  await StorageService.removeClient(client);
                  JavaService.instance.clients.remove(client.uuid);
                  updateHome();
                },
              )
            ],
          );
        },
      ),
    );
  }
}
