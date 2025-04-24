import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/config.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/login.dart';
import 'package:taulight/screens/qr_scanner_screen.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widgets/tau_buton.dart';

class ConnectionScreen extends StatefulWidget {
  final VoidCallback? updateHome;

  const ConnectionScreen({super.key, this.updateHome});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _linkController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Connect Hubs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Scan QR',
              onPressed: () {
                moveTo(context, QrScannerScreen(onScanned: (c, code) {
                  Navigator.pop(c);
                  _connect(context, code);
                }));
              },
            ),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        height: 300,
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(labelText: "sandnode-link"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter link";
                  }
                  try {
                    if (Uri.parse(value.trim()).scheme != "sandnode") {
                      return "Enter sandnode link";
                    }
                    return null;
                  } catch (e) {
                    return "Link not valid";
                  }
                },
              ),
            ),
            TauButton("Connect", onPressed: _connectPressed),
            const SizedBox(height: 20),
            const Text(
              "Recommended hubs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: Config.recommended.length,
                itemBuilder: (_, index) {
                  ServerRecord recommended = Config.recommended[index];
                  return TauButton(recommended.endpoint, onPressed: () {
                    _recommended(recommended.link);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recommended(String link) async {
    Client client;
    try {
      client = await JavaService.instance.connect(link, widget.updateHome);
    } on ConnectionException {
      if (mounted) {
        snackBar(context, "Connection exception: ${link2endpoint(link)}");
      }
      return;
    }
    await StorageService.saveClient(client);

    if (mounted) {
      LoginScreen screen = LoginScreen(
        client: client,
        updateHome: () {
          setState(() {});
          if (widget.updateHome != null) widget.updateHome!();
        },
        onSuccess: () {
          if (mounted) setState(() {});
        },
      );
      moveTo(context, screen);
    }
  }

  void _connectPressed() async {
    if (_formKey.currentState!.validate()) {
      _connect(context, _linkController.text.trim());
    }
  }

  void _connect(BuildContext context, String link) async {
    var client = await JavaService.instance.connect(link, widget.updateHome);
    await StorageService.saveClient(client);

    if (context.mounted) {
      LoginScreen screen = LoginScreen(
        client: client,
        updateHome: () {
          setState(() {});
          if (widget.updateHome != null) widget.updateHome!();
        },
        onSuccess: () {
          if (context.mounted) {
            setState(() {});
            Navigator.pop(context);
          }
        },
      );
      moveTo(context, screen);
    }
  }
}
