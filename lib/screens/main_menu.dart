import 'package:flutter/material.dart';
import 'package:taulight/enums/main_menu.dart';
import 'package:taulight/main_screens/connection.dart';
import 'package:taulight/main_screens/create_group.dart';
import 'package:taulight/main_screens/hubs.dart';
import 'package:taulight/main_screens/key_management.dart';
import 'package:taulight/main_screens/main_screen.dart';
import 'package:taulight/main_screens/start_dialog.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: TauAppBar.text("Taulight Agent"),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        children: [
          _section(
              "MAIN SCREENS",
              [
                _fromScreen(context, ConnectionScreen()),
                _fromScreen(context, HubsScreen()),
              ],
              colorScheme),
          _section(
              "GROUPS & DIALOGS",
              [
                _fromScreen(context, CreateGroupScreen()),
                _fromScreen(context, StartDialogScreen()),
              ],
              colorScheme),
          _section(
              "KEY MANAGEMENT",
              [
                _fromScreen(context, KeyManagementScreen()),
              ],
              colorScheme),
          _section(
              "ADDITIONAL",
              MainMenu.values.map((option) {
                return _compactTile(
                  icon: option.icon,
                  text: option.text,
                  onTap: () => option.action(),
                  colorScheme: colorScheme,
                );
              }).toList(),
              colorScheme),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> items, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 2),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _fromScreen(BuildContext context, IMainScreen screen) {
    final scheme = Theme.of(context).colorScheme;
    return _compactTile(
      icon: screen.icon(),
      text: screen.title(),
      onTap: () => Navigator.pop(context, screen),
      colorScheme: scheme,
    );
  }

  Widget _compactTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 18,
        color: colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
      ),
      dense: true,
      minLeadingWidth: 24,
      horizontalTitleGap: 6,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: onTap,
    );
  }
}
