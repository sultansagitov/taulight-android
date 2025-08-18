import 'package:flutter/material.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/tau_button.dart';

class TauAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;

  const TauAppBar({super.key, this.title, this.actions});

  factory TauAppBar.text(String title, {Key? key, List<Widget>? actions}) {
    return TauAppBar(
      key: key,
      title: Text(title),
      actions: actions,
    );
  }

  factory TauAppBar.empty({Key? key, List<Widget>? actions}) =>
      TauAppBar(key: key, actions: actions);

  factory TauAppBar.icon(
    ChatAvatar chatAvatar,
    String title, {
    Key? key,
    List<TauButton>? actions,
  }) {
    return TauAppBar(
      key: key,
      title: Row(children: [
        chatAvatar,
        const SizedBox(width: 12),
        Text(title),
      ]),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Colors.black,
      elevation: 2,
      titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            overflow: TextOverflow.ellipsis,
          ),
    );
  }
}
