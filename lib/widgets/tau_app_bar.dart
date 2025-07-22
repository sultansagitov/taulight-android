import 'package:flutter/material.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/tau_button.dart';

class TauAppBar extends AppBar {
  TauAppBar({super.key, super.title, super.actions});

  factory TauAppBar.text(String? title, {Key? key, List<Widget>? actions}) {
    if (title == null) {
      return TauAppBar(key: key, actions: actions);
    }

    return TauAppBar(
      key: key,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          overflow: TextOverflow.ellipsis,
        ),
      ),
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
      title: Row(
        children: [
          chatAvatar,
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
