import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/providers/message_time.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';

enum ChatMenuOptions {
  copy(Icons.copy, 'Copy ID', _copy);

  final IconData icon;
  final String text;
  final Future<void> Function(BuildContext, TauChat) action;

  const ChatMenuOptions(this.icon, this.text, this.action);
}

Future<void> _copy(BuildContext context, TauChat chat) async {
  await copy(context, chat.record.id);
}

Future<void> _onLongPressStart(
  BuildContext context,
  TauChat chat,
  LongPressStartDetails details,
) async {
  final pos = details.globalPosition;
  await showMenu(
    context: context,
    position: RelativeRect.fromLTRB(50, pos.dy, 50, pos.dy),
    items: ChatMenuOptions.values.map((opt) {
      return PopupMenuItem(
        child: Row(children: [
          Icon(opt.icon),
          const SizedBox(width: 4),
          Text(opt.text),
        ]),
        onTap: () => opt.action(context, chat),
      );
    }).toList(),
  );
}

class ChatItem extends ConsumerWidget {
  final TauChat chat;
  final void Function(TauChat) onTap;

  const ChatItem({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageTimeNotifier = ref.read(messageTimeNotifierProvider.notifier);

    final isLight = Theme.of(context).brightness == Brightness.light;
    ChatMessageWrapperDTO? wrapper = chat.messages.lastOrNull;

    Color? nicknameColor;
    final client = chat.client;
    final user = client.user;

    final view = wrapper?.view;
    if (view != null) {
      nicknameColor = getRandomColor(view.nickname.toString());
      if (!client.connected || user == null || !user.authorized) {
        nicknameColor = grey(nicknameColor);
      }
    }

    final textColor = Colors.grey[isLight ? 600 : 400];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(chat),
      onLongPressStart: (details) => _onLongPressStart(context, chat, details),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ChatAvatar(chat, d: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(
                      text: chat.record.getTitle(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (view == null) ...[
                    Text(
                      "No messages",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ] else if (!view.sys) ...[
                    Text.rich(
                      TextSpan(
                        children: [
                          if (isGroup(chat)) ...[
                            TextSpan(
                              text: view.nickname.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: nicknameColor,
                              ),
                            ),
                            TextSpan(
                              text: ": ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                          TextSpan(
                            text: wrapper!.decrypted ??
                                "Cannot decrypt message - ${wrapper.view.text}",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontStyle: wrapper.decrypted == null
                                  ? FontStyle.italic
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    Text(
                      parseSysMessages(chat, wrapper!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (view != null) ...[
              Text(
                "  ${formatTime(messageTimeNotifier.getDate(view))}",
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
