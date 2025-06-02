import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/config.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/login_screen.dart';
import 'package:taulight/screens/qr_scanner_screen.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/services/platform_service.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widgets/tau_button.dart';

class ConnectionScreen extends StatefulWidget {
  final VoidCallback? connectUpdate;

  const ConnectionScreen({super.key, this.connectUpdate});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _linkController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int? _loading;

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
            TauButton.icon(
              Icons.qr_code_scanner,
              onPressed: () async {
                var result = await moveTo(context, QrScannerScreen());
                if (result is String) {
                  _connect(context, result);
                }
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
                  } catch (e, stackTrace) {
                    print(e);
                    print(stackTrace);
                    return "Link not valid";
                  }
                },
              ),
            ),
            TauButton.text(
              "Connect",
              loading: _loading == -1,
              disable: _loading != null,
              onPressed: _connectPressed,
            ),
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
                  return TauButton.text(
                    "${recommended.name} : ${recommended.endpoint}",
                    loading: _loading == index,
                    disable: _loading != null,
                    onPressed: () async {
                      try {
                        setState(() => _loading ??= index);
                        await _recommended(recommended.link);
                      } finally {
                        setState(() => _loading = null);
                      }
                    },
                  );
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
      client = await PlatformService.ins.connect(
        link,
        connectUpdate: widget.connectUpdate,
      );
    } on ConnectionException {
      if (mounted) {
        snackBarError(context, "${link2endpoint(link)} connection failed");
      }
      return;
    }
    await StorageService.ins.saveClient(client);

    if (mounted) {
      var result = await moveTo(context, LoginScreen(client: client));
      if (result is String && result.contains("success")) {
        Navigator.pop(context, result);
      }
    }
  }

  void _connectPressed() async {
    if (_formKey.currentState!.validate()) {
      _connect(context, _linkController.text.trim());
    }
  }

  void _connect(BuildContext context, String link) async {
    try {
      setState(() => _loading ??= -1);
      var client = await PlatformService.ins.connect(
        link,
        connectUpdate: widget.connectUpdate,
      );
      await StorageService.ins.saveClient(client);

      if (context.mounted) {
        var result = await moveTo(context, LoginScreen(client: client));
        if (result is String && result.contains("success")) {
          Navigator.pop(context, result);
        }
      }
    } on ConnectionException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      if (mounted) {
        snackBarError(context, "Cannot connect to ${e.client.endpoint}");
      }
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      if (mounted) {
        snackBarError(context, "Unknown error");
      }
    } finally {
      setState(() => _loading = null);
    }
  }
}
