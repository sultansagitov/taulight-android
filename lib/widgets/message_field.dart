import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swipeable_tile/swipeable_tile.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/widgets/message_replies_widget.dart';
import 'package:taulight/widgets/tau_button.dart';

class MessageField extends StatefulWidget {
  final TauChat chat;
  final List<ChatMessageWrapperDTO> replies;
  final bool enabled;
  final FutureOr<void> Function(String) sendMessage;

  const MessageField({
    super.key,
    required this.chat,
    required this.replies,
    required this.enabled,
    required this.sendMessage,
  });

  @override
  State<MessageField> createState() => _MessageFieldState();
}

class _MessageFieldState extends State<MessageField> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> _sendMessage([String? text]) async {
    var t = (text ?? _messageController.text).trim();
    _messageController.clear();
    if (t.isEmpty) return;
    if (widget.enabled) widget.sendMessage(t);
  }

  @override
  Widget build(BuildContext context) {
    bool lightMode = Theme.of(context).brightness == Brightness.light;

    TauChat chat = widget.chat;
    bool enabled = widget.enabled;

    return Column(
      children: [
        Container(height: 1, color: Colors.grey),
        ...widget.replies.map(
          (r) => SwipeableTile(
            color: Colors.transparent,
            swipeThreshold: 0.2,
            isElevated: false,
            onSwiped: (_) => setState(() => widget.replies.remove(r)),
            backgroundBuilder: (_, __, ___) => Container(),
            key: UniqueKey(),
            direction: SwipeDirection.horizontal,
            child: ReplyPreviewWidget(chat: chat, reply: r),
          ),
        ),
        if (enabled)
          Row(
            children: [
              TauButton.icon(
                Icons.add,
                color: Colors.blue,
                onPressed: () {},
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    hintText: "Message as ${chat.client.user?.nickname}",
                    hintStyle: TextStyle(
                      color: Colors.grey[lightMode ? 600 : 400],
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    color: lightMode ? Colors.black : Colors.white,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: _sendMessage,
                ),
              ),
              TauButton.icon(
                Icons.arrow_forward_rounded,
                color: Colors.blue,
                onPressed: _sendMessage,
              ),
            ],
          )
        else
          SizedBox(
            height: 40,
            child: Center(child: Text("Disconnected")),
          ),
      ],
    );
  }
}
