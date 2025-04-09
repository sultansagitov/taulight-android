import 'package:flutter/material.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/utils.dart';

class MessageRepliesWidget extends StatelessWidget {
  final TauChat chat;
  final Message message;

  const MessageRepliesWidget({
    super.key,
    required this.chat,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (message.replies == null || message.replies!.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Message> validReplies = [];
    for (final id in message.replies!) {
      final replyMessage = chat.messages.where((m) => m.id == id).firstOrNull;
      if (replyMessage != null) {
        validReplies.add(replyMessage);
      }
    }

    if (validReplies.isEmpty) {
      return const SizedBox.shrink();
    }

    final isLight = Theme.of(context).brightness == Brightness.light;
    final replyBgColor = Colors.grey[isLight ? 100 : 850];

    final int userReplies = validReplies.where((m) => !m.sys).length;
    final int sysReplies = validReplies.where((m) => m.sys).length;

    String replyCountText;
    if (sysReplies > 0 && userReplies > 0) {
      var r = userReplies == 1 ? 'reply' : 'replies';
      var m = sysReplies == 1 ? 'system message' : 'system messages';
      replyCountText = "$userReplies $r • $sysReplies $m";
    } else if (sysReplies > 0) {
      var m = sysReplies == 1 ? 'system message' : 'system messages';
      replyCountText = "$sysReplies $m";
    } else if (userReplies > 0) {
      var r = userReplies == 1 ? 'reply' : 'replies';
      replyCountText = "$userReplies $r";
    } else {
      return const SizedBox.shrink();
    }

    final textColor = isLight ? Colors.black : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: replyBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[isLight ? 300 : 700]!, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Text(
              replyCountText,
              style: TextStyle(
                fontSize: 10,
                color: textColor.withAlpha(180),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...validReplies.map(
            (reply) => ReplyPreviewWidget(
              chat: chat,
              reply: reply,
            ),
          ),
        ],
      ),
    );
  }
}

class ReplyPreviewWidget extends StatelessWidget {
  final TauChat chat;
  final Message reply;

  const ReplyPreviewWidget({
    super.key,
    required this.chat,
    required this.reply,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;

    if (reply.sys) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 2,
              height: 20,
              color: Colors.grey,
              margin: const EdgeInsets.only(left: 4, right: 8, top: 2),
            ),
            Expanded(
              child: Center(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    parseSysMessages(chat, reply),
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    String previewText = reply.text;
    if (previewText.length > 50) {
      previewText = "${previewText.substring(0, 47)}...";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2,
            height: 20,
            color: getRandomColor(reply.nickname),
            margin: const EdgeInsets.only(left: 4, right: 8, top: 2),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.nickname,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: getRandomColor(reply.nickname),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatOnlyTime(reply.dateTime),
                      style: TextStyle(
                        fontSize: 8,
                        color: textColor.withAlpha(128),
                      ),
                    ),
                  ],
                ),
                Text(
                  previewText,
                  style: TextStyle(fontSize: 10, color: textColor),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
