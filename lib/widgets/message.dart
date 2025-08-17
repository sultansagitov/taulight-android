import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform/codes.dart';
import 'package:taulight/widgets/invite.dart';
import 'package:taulight/widgets/message_files_widget.dart';
import 'package:taulight/widgets/message_replies_widget.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widget_utils.dart';
import 'package:url_launcher/url_launcher.dart';

final RegExp urlRegExp = RegExp(
  r'(https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*))|'
  r'(sandnode:\/\/[^\/\s]+\/[a-zA-Z0-9/]+)',
  caseSensitive: false,
);

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
    final nickname = view.nickname.trim();

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
        ? _extractSandnodeUrl(message.decrypted!)
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
            constraints: BoxConstraints(maxWidth: width * 0.85, minWidth: 100),
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
                  _buildText(
                    context,
                    chat.client,
                    message.decrypted!,
                    textColor,
                  ),
                if (hasInvite) InviteWidget(chat, url),
                _buildFooter(context, view),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _name(BuildContext context, String nickname) {
  final isLight = Theme.of(context).brightness == Brightness.light;

  Color color = getRandomColor(nickname);
  if (isLight) color = dark(color);

  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      nickname,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: color,
      ),
    ),
  );
}

String? _extractSandnodeUrl(String text) {
  final RegExp sandnodeRegExp = RegExp(
    r'sandnode://[^/\s]+/invite/[a-zA-Z0-9]+',
    caseSensitive: false,
  );

  final match = sandnodeRegExp.firstMatch(text);
  return match?.group(0);
}

Widget _buildText(
  BuildContext context,
  Client client,
  String text,
  Color textColor,
) {
  final List<InlineSpan> spans = [];
  int lastMatchEnd = 0;

  for (final match in urlRegExp.allMatches(text)) {
    final String url = match.group(0)!;
    final int start = match.start;
    final int end = match.end;

    if (start > lastMatchEnd) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd, start),
          style: TextStyle(
            color: textColor,
          ),
        ),
      );
    }

    if (url.startsWith('sandnode://')) {
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final Uri uri = Uri.parse(url);
              final where = uri.path.split("/").where((s) => s.isNotEmpty);
              final code = [...where][1];

              String? error;

              try {
                await PlatformCodesService.ins.useCode(client, code);
              } on NotFoundException {
                error = "Code not found or not for you";
              } on NoEffectException {
                error = "Code used or expired";
              } on UnauthorizedException {
                error = "Code not for you";
              }

              if (context.mounted) {
                if (error != null) {
                  snackBarError(context, error);
                } else {
                  Navigator.pop(context);
                }
              }
            },
        ),
      );
    } else {
      spans.add(
        TextSpan(
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
        ),
      );
    }

    lastMatchEnd = end;
  }

  if (lastMatchEnd < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }

  return RichText(text: TextSpan(children: spans));
}

Row _buildFooter(BuildContext context, ChatMessageViewDTO view) {
  final theme = Theme.of(context);
  final isLight = theme.brightness == Brightness.light;
  final subTextColor = isLight ? Colors.black54 : Colors.white70;

  final loading = view.isLoading;
  final currentIcon = loading ? Icons.access_time_rounded : Icons.done;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(currentIcon, size: 10, color: subTextColor),
      const SizedBox(width: 4),
      if (view.keyID != null) ...[
        Icon(Icons.lock, size: 10, color: subTextColor),
        const SizedBox(width: 4),
      ],
      Text(
        formatOnlyTime(view.dateTime),
        style: TextStyle(fontSize: 10, color: subTextColor),
      ),
    ],
  );
}
