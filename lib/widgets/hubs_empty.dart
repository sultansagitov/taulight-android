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
                : IconButton(
                    onPressed: () => _loadChats(context),
                    icon: Icon(Icons.refresh),
                  ),
          ],
          const SizedBox(height: 10),
          TauButton("Connect to hub", onPressed: () {
            var screen = ConnectionScreen(
              updateHome: () {
                if (mounted) setState(() {});
                if (widget.updateHome != null) widget.updateHome!();
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
      try {
        await client.reload();
        if (widget.updateHome != null) widget.updateHome!();
      } on ConnectionException {
        if (context.mounted) {
          snackBar(context, "Connection error: ${client.name}");
        }
      } on UnauthorizedException {
        if (context.mounted) {
          snackBar(context, "Unauthorized error: ${client.name}");
        }
      } finally {
        setState(() => loadingChats = false);
      }
    }
  }
}
