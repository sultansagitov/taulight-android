import 'package:flutter/material.dart';
import 'package:taulight/screens/hubs.dart';
import 'package:taulight/services/client.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

abstract class AuthState<T extends StatefulWidget> extends State<T> {
  Widget authorizedBuild(BuildContext context);

  @override
  Widget build(BuildContext context) {
    var clients = ClientService.ins.clientsList;
    var auth = clients.any((c) => c.authorized);

    if (auth) return authorizedBuild(context);

    return Scaffold(
      appBar: TauAppBar.text("Not authorized"),
      body: HubsScreenState.buildScreen(context, clients, () => setState(() {})),
    );
  }
}
