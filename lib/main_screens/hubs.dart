import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/main_screens/main_screen.dart';
import 'package:taulight/services/client.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/main_screens/connection.dart';
import 'package:taulight/widgets/hub_item.dart';
import 'package:taulight/widgets/hubs_empty.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
import 'package:taulight/widgets/tau_button.dart';

class HubsScreen extends StatefulWidget implements IMainScreen {
  final VoidCallback? connectUpdate;

  const HubsScreen({super.key, this.connectUpdate});

  @override
  IconData icon() => Icons.person_outlined;
  @override
  String title() => "Show hubs and profile";

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
    final clients = ClientService.ins.clientsList;

    return Scaffold(
      appBar: TauAppBar.text("Hubs", actions: [
        TauButton.icon(Icons.add, onPressed: () async {
          final screen = ConnectionScreen(connectUpdate: _connectUpdate);
          final result = await moveTo(context, screen);
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
        children: clients.map((c) => HubItem(c, connectUpdate)).toList(),
      ),
    );
  }
}
