import 'package:flutter/material.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/utils.dart';

class ChatItem extends StatelessWidget {
  final TauChat chat;
  final void Function(TauChat) onTap;

  final bool dup;

  const ChatItem({
    super.key,
    required this.chat,
    required this.onTap,
    required this.dup,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final isDialog = chat.record is DialogDTO;
    var d = 52;

    ChatMessageViewDTO? message;
    if (chat.messages.isNotEmpty) {
      message = chat.messages.last;
    }

    Color? nicknameColor;
    bool connected = chat.client.connected;

    if (message != null) {
      nicknameColor = getRandomColor(message.nickname);
      if (!connected || chat.client.user == null || !chat.client.user!.authorized) {
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
            if (isDialog)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: d.toDouble(),
                  height: d.toDouble(),
                  color: Colors.black,
                ),
              )
            else
              CircleAvatar(
                radius: d / 2,
                // backgroundImage: getImage(chat),
                backgroundColor: Colors.black,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(children: [
                      if (dup)
                        TextSpan(
                          text: "(as ${chat.client.user!.nickname}) ",
                          style: const TextStyle(fontSize: 16),
                        ),
                      TextSpan(
                        text: chat.getTitle(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  if (message == null) ...[
                    Text(
                      "No messages",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ] else if (!message.sys) ...[
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: message.nickname,
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
                          TextSpan(
                            text: message.text,
                            style: TextStyle(color: textColor, fontSize: 14),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    Text(
                      parseSysMessages(chat, message),
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
            if (message != null) ...[
              Text(
                "  ${formatTime(message.dateTime)}",
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
