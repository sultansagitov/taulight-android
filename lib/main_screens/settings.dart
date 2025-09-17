import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taulight/main_screens/main_screen.dart';
import 'package:taulight/providers/message_time.dart';
import 'package:taulight/providers/server_key.dart';
import 'package:taulight/providers/theme.dart';
import 'package:taulight/screens/pin.dart';
import 'package:taulight/services/storage.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
import 'package:taulight/widgets/tip.dart';

class SettingsScreen extends ConsumerWidget implements IMainScreen {
  const SettingsScreen({super.key});

  @override
  IconData icon() => Icons.settings;
  @override
  String title() => "Settings";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    final messageTimeState = ref.watch(messageTimeNotifierProvider);
    final serverKeyState = ref.watch(serverKeyNotifierProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: TauAppBar.text("Settings"),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Tip("Switch between light, dark or system theme."),
          ),

          ListTile(
            title: const Text("Theme"),
            subtitle: Text(themeState.themeMode.name),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: ThemeMode.values.map((mode) {
                final selected = themeState.themeMode == mode;
                Widget inner;
                Color borderColor;

                switch (mode) {
                  case ThemeMode.system:
                    inner = Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: Column(
                          children: [
                            Expanded(child: Container(color: Colors.white)),
                            Expanded(child: Container(color: Colors.black)),
                          ],
                        ),
                      ),
                    );
                    borderColor = isDark ? Colors.white : Colors.black;
                    break;
                  case ThemeMode.light:
                    inner = const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    );
                    borderColor = Colors.black;
                    break;
                  case ThemeMode.dark:
                    inner = const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                    );
                    borderColor = Colors.white;
                    break;
                }

                return GestureDetector(
                  onTap: () =>
                      ref.read(themeNotifierProvider.notifier).setTheme(mode),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor,
                        width: selected ? 4 : 1,
                      ),
                    ),
                    child: inner,
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(),

          // Message Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Tip('''
              Choose whether to display the message time
              as the moment it was sent or the server's recorded time.
            '''),
          ),

          ListTile(
            title: const Text("Message Date"),
            subtitle: Text(
              messageTimeState.dateOption == MessageDateOption.send
                  ? "Show Send Time"
                  : "Show Server Time",
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            trailing: SegmentedButton<MessageDateOption>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return isDark ? Colors.grey[800] : Colors.grey[300];
                  }
                  return isDark ? Colors.grey[900] : Colors.grey[200];
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return isDark ? Colors.white : Colors.black;
                  }
                  return isDark ? Colors.grey[400] : Colors.grey[800];
                }),
              ),
              segments: const [
                ButtonSegment(
                  value: MessageDateOption.send,
                  label: Text("Send"),
                  icon: Icon(Icons.send_time_extension),
                ),
                ButtonSegment(
                  value: MessageDateOption.server,
                  label: Text("Server"),
                  icon: Icon(Icons.cloud),
                ),
              ],
              selected: {messageTimeState.dateOption},
              onSelectionChanged: (sel) {
                ref
                    .read(messageTimeNotifierProvider.notifier)
                    .setDateOption(sel.first);
              },
            ),
          ),

          const Divider(),

          // Use key from server
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Tip('''
              When enabled, the decryption key is retrieved from the server
              together with the shared link (text or QR). This method is not
              secure, as the key is transmitted without encryption and may be
              exposed to man-in-the-middle attacks.
            '''),
          ),

          ListTile(
            title: const Text("Use key from server"),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            trailing: Switch(
                value: serverKeyState.fetch,
                onChanged: (fetch) {
                  ref.read(serverKeyNotifierProvider.notifier).setFetch(fetch);
                }),
          ),

          const Divider(),

          ListTile(
            title: const Text("PIN Code"),
            subtitle: FutureBuilder<String?>(
              future: StorageService.ins.getPIN(),
              builder: (context, snapshot) {
                final pin = snapshot.data;
                return Text(pin != null ? "****" : "Not set");
              },
            ),
            trailing: ElevatedButton(
              child: const Text("Set/Change"),
              onPressed: () async {
                final testScreen = PinScreen(
                  useFingerprintIfExists: false,
                  onSuccess: (context) async {
                    Navigator.pop(context, "success");
                    await StorageService.ins.cleanPIN();
                  },
                );
                final result = await moveTo(context, testScreen);
                if (result != "success") return;

                final updatingScreen = PinScreen(
                  useFingerprintIfExists: false,
                  onSuccess: (context) => Navigator.pop(context),
                );
                await moveTo(context, updatingScreen);
              },
            ),
          ),
        ],
      ),
    );
  }
}
