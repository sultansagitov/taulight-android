import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/widgets/message_replies_widget.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widget_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageWidget extends StatefulWidget {
  final TauChat chat;
  final ChatMessageViewDTO message;
  final ChatMessageViewDTO? prev;
  final ChatMessageViewDTO? next;

  const MessageWidget({
    super.key,
    required this.chat,
    required this.message,
    required this.prev,
    required this.next,
  });

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  Future<Widget>? inviteDetails;

  Widget name(BuildContext context, String nickname) {
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

  String? extractSandnodeUrl(String text) {
    final RegExp sandnodeRegExp = RegExp(
      r'sandnode://[^/\s]+/invite/[a-zA-Z0-9]+',
      caseSensitive: false,
    );

    final match = sandnodeRegExp.firstMatch(text);
    return match?.group(0);
  }

  String? extractInviteCode(String url) {
    final RegExp inviteRegExp = RegExp(r'invite/([a-zA-Z0-9]+)');
    final match = inviteRegExp.firstMatch(url);
    return match?.group(1);
  }

  Widget parseLinks(BuildContext context, String text, Color textColor) {
    final RegExp urlRegExp = RegExp(
      r'(https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*))|'
      r'(sandnode:\/\/[^\/\s]+\/invite\/[a-zA-Z0-9]+)',
      caseSensitive: false,
    );

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
                var where = uri.path.split("/").where((s) => s.isNotEmpty);
                var code = [...where][1];
                try {
                  await widget.chat.client.useCode(code);
                } on NotFoundException {
                  if (context.mounted) {
                    snackBar(context, "Code not found or not for you");
                  }
                  return;
                } on NoEffectException {
                  if (context.mounted) {
                    snackBar(context, "Code used or expired");
                  }
                  return;
                } on UnauthorizedException {
                  if (context.mounted) {
                    snackBar(context, "Code not for you");
                  }
                  return;
                }

                if (context.mounted) {
                  snackBar(context, "Code used");
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

  Future<Widget> buildInviteDetails(BuildContext context, String url) async {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;
    final Uri uri = Uri.parse(url);
    var where = uri.path.split("/").where((s) => s.isNotEmpty);
    var codeString = where.elementAt(1);

    var code = await widget.chat.client
        .checkCode(codeString)
        .timeout(Duration(seconds: 5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            //TODO Rounded circle placeholder for channel image
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Container(width: 40, height: 40, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Text(
              code.title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                color: textColor.withAlpha(180),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'From: ${code.sender}',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: textColor.withAlpha(180)),
        ),
        const SizedBox(height: 4),
        if (code.activation == null)
          Row(
            children: [
              Icon(
                code.isExpired ? Icons.timer_off : Icons.timer,
                size: 14,
                color: code.isExpired ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                'Expires: ${formatFutureTime(code.expires.toLocal())}',
                style: TextStyle(
                  fontSize: 12,
                  color: code.isExpired ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        if (code.activation != null) ...[
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.red, size: 14),
              const SizedBox(width: 4),
              Text(
                'Activated: ${formatTime(code.activation!.toLocal())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        if (code.isExpired && code.activation == null) ...[
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 14),
              const SizedBox(width: 4),
              Text(
                'Invitation expired',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.sys) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            parseSysMessages(widget.chat, widget.message),
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

    var width = MediaQuery.of(context).size.width;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final nickname = widget.message.nickname;

    final first = widget.prev?.sys == true || nickname != widget.prev?.nickname;
    final last = widget.next?.sys == true || nickname != widget.next?.nickname;

    final loading = widget.message.id.startsWith("temp_");

    final MainAxisAlignment align;
    final Color? bgColor;
    if (widget.message.isMe) {
      align = MainAxisAlignment.end;
      bgColor = Colors.blue[isLight ? 100 : 900];
    } else {
      align = MainAxisAlignment.start;
      bgColor = Colors.grey[isLight ? 200 : 800];
    }

    final currentIcon = loading ? Icons.access_time_rounded : Icons.done;

    final textColor = isLight ? Colors.black : Colors.white;
    final subTextColor = isLight ? Colors.black54 : Colors.white70;

    final url = extractSandnodeUrl(widget.message.text);
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
                topLeft: Radius.circular(widget.message.isMe ? 6 : 16),
                topRight: Radius.circular(widget.message.isMe ? 16 : 6),
                bottomLeft: Radius.circular(widget.message.isMe ? 16 : 6),
                bottomRight: Radius.circular(widget.message.isMe ? 6 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (first && !widget.message.isMe) name(context, nickname),

                // Show replies first if available
                if (widget.message.repliedToMessages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MessageRepliesWidget(
                      chat: widget.chat,
                      message: widget.message,
                    ),
                  ),

                // Message text content
                parseLinks(context, widget.message.text, textColor),

                // Invite details if present
                if (hasInvite)
                  FutureBuilder(
                    future: inviteDetails ??= buildInviteDetails(context, url),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print("Error when loading invite ${snapshot.error}");
                      }

                      if (snapshot.data == null) {
                        return Container();
                      }

                      return snapshot.data!;
                    },
                  ),

                // Message timestamp
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(currentIcon, size: 10, color: subTextColor),
                    const SizedBox(width: 4),
                    Text(
                      formatOnlyTime(widget.message.dateTime),
                      style: TextStyle(fontSize: 10, color: subTextColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
