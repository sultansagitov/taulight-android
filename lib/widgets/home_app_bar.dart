import 'package:flutter/material.dart';
import 'package:taulight/config.dart';
import 'package:taulight/services/client.dart';
import 'package:taulight/widgets/animated_greetings.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
import 'package:taulight/widgets/tau_button.dart';
import 'package:taulight/widgets/tau_loading.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool loadingChats;
  final VoidCallback menuPressed;
  final VoidCallback searchPressed;

  const HomeAppBar({
    super.key,
    required this.loadingChats,
    required this.menuPressed,
    required this.searchPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final color = Config.primarySwatch[isLight ? 700 : 300];

    final names = ClientService.ins.clientsList
        .where((c) => c.user != null)
        .map((c) => c.user!.nickname)
        .toList();

    return TauAppBar(
      title: Row(
        children: [
          TauButton.icon(
            Icons.menu,
            color: color,
            onPressed: menuPressed,
          ),
          if (loadingChats)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: TauLoading(),
            ),
          Expanded(child: AnimatedGreeting(names: names)),
          TauButton.icon(
            Icons.search,
            color: color,
            onPressed: searchPressed,
          ),
        ],
      ),
    );
  }
}
