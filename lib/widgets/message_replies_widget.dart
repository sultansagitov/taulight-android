import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/utils.dart';

class MessageRepliesWidget extends StatelessWidget {
  final TauChat chat;
  final ChatMessageViewDTO message;

  const MessageRepliesWidget({
    super.key,
    required this.chat,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (message.repliedToMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<ChatMessageWrapperDTO> validReplies = [];
    for (final id in message.repliedToMessages) {
      final replyMessage =
          chat.messages.where((m) => m.view.id == id).firstOrNull;
      if (replyMessage != null) {
        validReplies.add(replyMessage);
      }
    }

    if (validReplies.isEmpty) {
      return const SizedBox.shrink();
    }

    final isLight = Theme.of(context).brightness == Brightness.light;
    final replyBgColor = Colors.grey[isLight ? 100 : 850];

    final int userReplies = validReplies.where((m) => !m.view.sys).length;
    final int sysReplies = validReplies.where((m) => m.view.sys).length;

    String replyCountText;
    if (sysReplies > 0 && userReplies > 0) {
      final r = userReplies == 1 ? 'reply' : 'replies';
      final m = sysReplies == 1 ? 'system message' : 'system messages';
      replyCountText = "$userReplies $r • $sysReplies $m";
    } else if (sysReplies > 0) {
      final m = sysReplies == 1 ? 'system message' : 'system messages';
      replyCountText = "$sysReplies $m";
    } else if (userReplies > 0) {
      final r = userReplies == 1 ? 'reply' : 'replies';
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
  final ChatMessageWrapperDTO reply;

  const ReplyPreviewWidget({
    super.key,
    required this.chat,
    required this.reply,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;

    final message = reply.view;
    if (message.sys) {
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

    final decrypted = reply.decrypted != null;
    String previewText =
        reply.decrypted ?? "Cannot decrypt message - ${reply.view.text}";
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
            color: getRandomColor(message.nickname.toString()),
            margin: const EdgeInsets.only(left: 4, right: 8, top: 2),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.nickname.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: getRandomColor(message.nickname.toString()),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatOnlyTime(message.dateTime),
                      style: TextStyle(
                        fontSize: 8,
                        color: textColor.withAlpha(128),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ...message.files.take(3).map(_buildReply),
                    Expanded(
                      child: Text(
                        previewText,
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor,
                          fontStyle: !decrypted ? FontStyle.italic : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
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

  Widget _buildReply(NamedFileDTO file) {
    String data = file.filename.length > 10
        ? "${file.filename.substring(0, 10)}..."
        : file.filename;
    return Container(
      color: Colors.grey.withAlpha(32),
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(4),
      child: Text(data, style: TextStyle(fontSize: 9)),
    );
  }
}
