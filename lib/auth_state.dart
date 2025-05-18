import 'package:flutter/material.dart';
import 'package:taulight/screens/hubs_screen.dart';
import 'package:taulight/services/client_service.dart';

abstract class AuthState<T extends StatefulWidget> extends State<T> {
  Widget authorizedBuild(BuildContext context);

  @override
  Widget build(BuildContext context) {
    var clients = ClientService.instance.clientsList;
    var auth = clients.any((c) => c.authorized);

    if (auth) return authorizedBuild(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Not authorized")),
      body: HubsScreenState.buildScreen(clients, () => setState(() {})),
    );
  }
}
