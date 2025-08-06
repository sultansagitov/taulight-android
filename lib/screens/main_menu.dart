import 'package:flutter/material.dart';
import 'package:taulight/enums/main_menu.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TauAppBar.text("Taulight Agent"),
      body: ListView(
        children: MainMenu.values.map((option) {
          return ListTile(
            leading: Icon(option.icon),
            title: Text(option.text),
            onTap: () => option.action(context, () => setState(() {})),
          );
        }).toList(),
      ),
    );
  }
}
