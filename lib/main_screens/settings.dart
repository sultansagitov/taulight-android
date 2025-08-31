import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taulight/main_screens/main_screen.dart';
import 'package:taulight/providers/message_time.dart';
import 'package:taulight/providers/theme.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

class SettingsScreen extends StatelessWidget implements IMainScreen {
  const SettingsScreen({super.key});

  @override
  IconData icon() => Icons.settings;
  @override
  String title() => "Settings";

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final messageTimeProvider = context.watch<MessageTimeProvider>();

    return Scaffold(
      appBar: TauAppBar.text("Settings"),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          ListTile(
            title: const Text("Theme"),
            subtitle: Text(themeProvider.themeMode.name),
            trailing: SegmentedButton<ThemeMode>(
              segments: ThemeMode.values.map((mode) {
                return ButtonSegment(
                  value: mode,
                  label: Text(mode.name),
                  icon: mode == ThemeMode.system
                      ? const Icon(Icons.phone_android)
                      : mode == ThemeMode.light
                      ? const Icon(Icons.light_mode)
                      : const Icon(Icons.dark_mode),
                );
              }).toList(),
              selected: {themeProvider.themeMode},
              onSelectionChanged: (sel) {
                themeProvider.setTheme(sel.first);
              },
            ),
          ),
          const Divider(),

          // Message Date
          ListTile(
            title: const Text("Message Date"),
            subtitle: Text(
              messageTimeProvider.dateOption == MessageDateOption.send
                  ? "Show Send Time"
                  : "Show Server Time",
            ),
            trailing: SegmentedButton<MessageDateOption>(
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
              selected: {messageTimeProvider.dateOption},
              onSelectionChanged: (sel) {
                messageTimeProvider.setDateOption(sel.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}
