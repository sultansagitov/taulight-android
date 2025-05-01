import 'package:flutter/material.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/connection_screen.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/widgets/tau_button.dart';

class HubsEmpty extends StatefulWidget {
  final VoidCallback? updateHome;

  const HubsEmpty({super.key, this.updateHome});

  @override
  State<HubsEmpty> createState() => _HubsEmptyState();
}

class _HubsEmptyState extends State<HubsEmpty> {
  bool loadingChats = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("No hubs connected", style: TextStyle(fontSize: 18)),
          if (JavaService.instance.clients.isNotEmpty) ...[
            const SizedBox(height: 10),
            loadingChats
                ? CircularProgressIndicator()
                : TauButton.icon(
                    Icons.refresh,
                    onPressed: () => _loadChats(context),
                  ),
          ],
          const SizedBox(height: 10),
          TauButton.text("Connect to hub", onPressed: () {
            var screen = ConnectionScreen(
              updateHome: () {
                if (mounted) setState(() {});
                widget.updateHome?.call();
              },
            );
            moveTo(context, screen);
          }),
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
        widget.updateHome?.call();
      } on ConnectionException {
        error = "Connection error: ${client.name}";
      } on UnauthorizedException {
        error = "Unauthorized error: ${client.name}";
      } finally {
        setState(() => loadingChats = false);
      }

      if (error != null && context.mounted) {
        snackBarError(context, error);
      }
    }
  }
}
