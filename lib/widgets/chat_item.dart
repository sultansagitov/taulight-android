import 'package:flutter/material.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';

class ChatItem extends StatelessWidget {
  final TauChat chat;
  final void Function(TauChat) onTap;

  const ChatItem({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    ChatMessageWrapperDTO? wrapper;
    if (chat.messages.isNotEmpty) {
      wrapper = chat.messages.last;
    }

    Color? nicknameColor;
    var client = chat.client;
    var user = client.user;

    var view = wrapper?.view;
    if (view != null) {
      nicknameColor = getRandomColor(view.nickname);
      if (!client.connected || user == null || !user.authorized) {
        nicknameColor = grey(nicknameColor);
      }
    }

    var textColor = Colors.grey[isLight ? 600 : 400];

    return InkWell(
      onTap: () => onTap(chat),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ChatAvatar(chat, d: 52),
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
                        fontSize: 16,
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
                          if (isChannel(chat)) ...[
                            TextSpan(
                              text: view.nickname,
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
                            text: wrapper!.decrypted ?? // TODO possible null
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
                      parseSysMessages(chat, wrapper!), // TODO possible null
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
                "  ${formatTime(view.dateTime)}",
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
