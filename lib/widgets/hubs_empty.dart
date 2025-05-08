import 'package:flutter/material.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/connection_screen.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/widgets/tau_button.dart';

class HubsEmpty extends StatefulWidget {
  final VoidCallback? connectUpdate;

  const HubsEmpty({super.key, this.connectUpdate});

  @override
  State<HubsEmpty> createState() => _HubsEmptyState();
}

class _HubsEmptyState extends State<HubsEmpty> {
  bool loadingChats = false;

  void _connectUpdate() {
    if (mounted) setState(() {});
    widget.connectUpdate?.call();
  }

  @override
  Widget build(BuildContext context) {
    var clients = JavaService.instance.clients;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          const Text(
            "No hubs connected",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (clients.isNotEmpty) ...[
            const SizedBox(height: 10),
            TauButton.icon(
              Icons.refresh,
              loading: loadingChats,
              onPressed: () => _loadChats(context),
            ),
            Text("Reconnect disconnected hubs (${clients.length})"),
          ],
          const SizedBox(height: 12),
          TauButton.text(
            "Connect to hub",
            onPressed: () async {
              var screen = ConnectionScreen(connectUpdate: _connectUpdate);
              await moveTo(context, screen);
              _connectUpdate();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadChats(BuildContext context) async {
    setState(() => loadingChats = true);
    var clients = List.of(JavaService.instance.clients.values);
    for (var client in clients) {
      String? error;

      try {
        await client.reload();
      } on ConnectionException {
        error = "Connection error: ${client.name}";
      } on UnauthorizedException {
        // Ignored: will be reflected after updateHome on HomeScreen
      } finally {
        widget.connectUpdate?.call();
        setState(() => loadingChats = false);
      }

      if (error != null && context.mounted) {
        snackBarError(context, error);
      }
    }
  }
}
