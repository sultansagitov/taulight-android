import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/nickname.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/message_helpers.dart';
import 'package:taulight/providers/message_time.dart';
import 'package:taulight/widgets/message_files_widget.dart';
import 'package:taulight/widgets/message_replies_widget.dart';
import 'package:taulight/widgets/invite.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageWidget extends StatelessWidget {
  final TauChat chat;
  final ChatMessageWrapperDTO message;
  final ChatMessageWrapperDTO? prev;
  final ChatMessageWrapperDTO? next;

  const MessageWidget({
    super.key,
    required this.chat,
    required this.message,
    required this.prev,
    required this.next,
  });

  @override
  Widget build(BuildContext context) {
    final view = message.view;
    if (view.sys) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            parseSysMessages(chat, message),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final nickname = view.nickname;

    final first = prev?.view.sys == true || nickname != prev?.view.nickname;
    final last = next?.view.sys == true || nickname != next?.view.nickname;

    final MainAxisAlignment align;
    final Color? bgColor;
    if (view.isMe) {
      align = MainAxisAlignment.end;
      bgColor = Colors.blue[isLight ? 100 : 900];
    } else {
      align = MainAxisAlignment.start;
      bgColor = Colors.grey[isLight ? 200 : 800];
    }

    final textColor = isLight ? Colors.black : Colors.white;

    final url = message.decrypted != null
        ? extractSandnodeUrl(message.decrypted!)
        : null;
    final hasInvite = url != null;

    return Padding(
      padding: EdgeInsets.only(
        top: first ? 4 : 2,
        bottom: last ? 4 : 2,
        left: 8,
        right: 8,
      ),
      child: Row(
        mainAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: width * 0.85,
              minWidth: 100,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(view.isMe ? 6 : 16),
                topRight: Radius.circular(view.isMe ? 16 : 6),
                bottomLeft: Radius.circular(view.isMe ? 16 : 6),
                bottomRight: Radius.circular(view.isMe ? 6 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isDialog(chat) && first && !view.isMe)
                  _name(context, nickname),
                if (view.repliedToMessages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MessageRepliesWidget(
                      chat: chat,
                      message: view,
                    ),
                  ),
                if (view.files.isNotEmpty) MessageFilesWidget(chat, view),
                if (message.decrypted == null)
                  Text(
                    "Cannot decrypt message - ${message.view.text}",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  )
                else if (message.decrypted!.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      children: parseMessage(
                        text: message.decrypted!,
                        regular: (text) {
                          return _buildRegular(text, textColor);
                        },
                        sandnodeLink: (url) {
                          return _buildSandnodeLink(context, url);
                        },
                        link: (url) {
                          return _buildLink(url);
                        },
                      ),
                    ),
                  ),
                if (hasInvite) InviteWidget(chat, url),
                _buildFooter(context, message),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildRegular(String substring, Color textColor) {
    return TextSpan(
      text: substring,
      style: TextStyle(fontSize: 12, color: textColor),
    );
  }

  TextSpan _buildSandnodeLink(BuildContext context, String url) {
    return TextSpan(
      text: url,
      style: TextStyle(
        fontSize: 12,
        color: Colors.green,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () => sandnodeLinkPressed(context, chat.client, url),
    );
  }

  TextSpan _buildLink(String url) {
    return TextSpan(
      text: url,
      style: TextStyle(
        fontSize: 12,
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
    );
  }
}

Widget _name(BuildContext context, Nickname nickname) {
  final isLight = Theme.of(context).brightness == Brightness.light;

  Color color = getRandomColor(nickname.toString());
  if (isLight) color = dark(color);

  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      nickname.toString(),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: color,
      ),
    ),
  );
}

Widget _buildFooter(BuildContext context, ChatMessageWrapperDTO message) {
  final provider = context.watch<MessageTimeProvider>();

  final theme = Theme.of(context);
  final isLight = theme.brightness == Brightness.light;
  final subTextColor = isLight ? Colors.black54 : Colors.white70;

  final loading = message.isLoading;
  final currentIcon = loading ? Icons.access_time_rounded : Icons.done;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(currentIcon, size: 10, color: subTextColor),
      const SizedBox(width: 4),
      if (message.view.keyID != null) ...[
        Icon(Icons.lock, size: 10, color: subTextColor),
        const SizedBox(width: 4),
      ],
      Text(
        formatOnlyTime(provider.getDate(message.view)),
        style: TextStyle(fontSize: 10, color: subTextColor),
      ),
    ],
  );
}
