import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/config.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform/client.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/login.dart';
import 'package:taulight/screens/hub_qr_scanner.dart';
import 'package:taulight/services/storage.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widgets/flat_rect_button.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
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
      appBar: TauAppBar.text("Connect Hubs", actions: [
        TauButton.icon(
          Icons.qr_code_scanner,
          onPressed: () async {
            final result = await moveTo(context, QrScannerScreen());
            if (result is String) {
              _connect(context, result);
            }
          },
        ),
      ]),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: const EdgeInsets.all(8.0),
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
            const SizedBox(height: 6),
            FlatRectButton(
              label: "Connect",
              loading: _loading == -1,
              disable: _loading != null,
              onPressed: _connectPressed,
            ),
            const SizedBox(height: 20),
            const Text(
              "Recommended hubs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Column(
              children: Config.recommended.asMap().entries.map((entry) {
                ServerRecord recommended = entry.value;
                int index = entry.key;

                return FlatRectButton(
                  label: "${recommended.name} : ${recommended.address}",
                  margin: const EdgeInsets.only(bottom: 8),
                  loading: _loading == index,
                  disable: _loading != null,
                  width: double.infinity,
                  onPressed: () async {
                    try {
                      setState(() => _loading ??= index);
                      await _recommended(recommended.link);
                    } finally {
                      setState(() => _loading = null);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recommended(String link) async {
    Client client;
    try {
      client = await PlatformClientService.ins.connect(
        link,
        connectUpdate: widget.connectUpdate,
      );
    } on ConnectionException {
      if (mounted) {
        snackBarError(context, "${link2address(link)} connection failed");
      }
      return;
    }
    await StorageService.ins.saveClient(client);

    if (mounted) {
      final result = await moveTo(context, LoginScreen(client: client));
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
      final client = await PlatformClientService.ins.connect(
        link,
        connectUpdate: widget.connectUpdate,
      );
      await StorageService.ins.saveClient(client);

      if (context.mounted) {
        final result = await moveTo(context, LoginScreen(client: client));
        if (result is String && result.contains("success")) {
          Navigator.pop(context, result);
        }
      }
    } on ConnectionException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      if (mounted) {
        snackBarError(context, "Cannot connect to ${e.client.address}");
      }
    } on InvalidSandnodeLinkException catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      if (mounted) {
        snackBarError(context, "Invalid link or changed key");
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
