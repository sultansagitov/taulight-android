import 'package:flutter/material.dart';
import 'package:taulight/config.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/main_screens/main_screen.dart';
import 'package:taulight/services/platform/client.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/login.dart';
import 'package:taulight/screens/qr_scanner.dart';
import 'package:taulight/services/storage.dart';
import 'package:taulight/widgets/flat_rect_button.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
import 'package:taulight/widgets/tau_button.dart';

class ConnectionScreen extends StatefulWidget implements IMainScreen {
  final VoidCallback? connectUpdate;

  const ConnectionScreen({super.key, this.connectUpdate});

  @override
  IconData icon() => Icons.link_outlined;
  @override
  String title() => "Connect";

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _linkController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// -1 = manual link connect, >=0 = recommended index
  final ValueNotifier<int?> _loading = ValueNotifier(null);

  @override
  void dispose() {
    _linkController.dispose();
    _loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TauAppBar.text("Connect Hubs", actions: [
        TauButton.icon(
          Icons.qr_code_scanner,
          onPressed: () async {
            final result = await moveTo(context, QrScannerScreen());
            if (result is String) {
              _connect(result, index: -1);
            }
          },
        ),
      ]),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                  return null;
                },
              ),
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<int?>(
              valueListenable: _loading,
              builder: (_, loading, __) {
                return FlatRectButton(
                  label: "Connect",
                  loading: loading == -1,
                  disable: loading != null,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _connect(_linkController.text.trim(), index: -1);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Recommended hubs",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ValueListenableBuilder<int?>(
              valueListenable: _loading,
              builder: (_, loading, __) {
                return Column(
                  children: Config.recommended.asMap().entries.map((entry) {
                    final recommended = entry.value;
                    final index = entry.key;

                    return FlatRectButton(
                      label: "${recommended.name} : ${recommended.address}",
                      margin: const EdgeInsets.only(bottom: 8),
                      loading: loading == index,
                      disable: loading != null,
                      width: double.infinity,
                      onPressed: () => _connect(recommended.link, index: index),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connect(String link, {required int index}) async {
    try {
      _loading.value = index;
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
    } on InvalidSandnodeLinkException {
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
      _loading.value = null;
    }
  }
}
