import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taulight/main_screens/main_screen.dart';
import 'package:taulight/providers/message_time.dart';
import 'package:taulight/providers/theme.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: TauAppBar.text("Settings"),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          ListTile(
            title: const Text("Theme"),
            subtitle: Text(themeState.themeMode.name),
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
          ListTile(
            title: const Text("Message Date"),
            subtitle: Text(
              messageTimeState.dateOption == MessageDateOption.send
                  ? "Show Send Time"
                  : "Show Server Time",
            ),
            trailing: SegmentedButton<MessageDateOption>(
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
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
        ],
      ),
    );
  }
}
