import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/dialogs/hub_dialog.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/widget_utils.dart';

class WarningDisconnectMessage extends StatefulWidget {
  final Client client;
  final VoidCallback? updateHome;

  const WarningDisconnectMessage({
    super.key,
    this.updateHome,
    required this.client,
  });

  @override
  State<WarningDisconnectMessage> createState() {
    return _WarningDisconnectMessageState();
  }
}

class _WarningDisconnectMessageState extends State<WarningDisconnectMessage> {
  bool loading = false;

  void _refresh() async {
    setState(() => loading = true);
    try {
      await widget.client.reload();
    } on ConnectionException {
      if (mounted) {
        snackBar(context, "Connection exception: ${widget.client.name}");
      }
    } finally {
      setState(() => loading = false);
      if (widget.updateHome != null) widget.updateHome!();
    }
  }

  void _visibilityOff() {
    widget.client.hide = true;
    if (widget.updateHome != null) widget.updateHome!();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red[200],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => openHubDialog(context, widget.client),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.black),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.client.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                  const Text(
                    " disconnected",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          if (!loading) ...[
            IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.refresh, color: Colors.black),
              onPressed: _refresh,
            ),
            IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.visibility_off, color: Colors.black),
              onPressed: _visibilityOff,
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(4),
              child: CircularProgressIndicator(color: Colors.black),
            ),
          ]
        ],
      ),
    );
  }
}
