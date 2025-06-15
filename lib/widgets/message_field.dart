import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swipeable_tile/swipeable_tile.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widgets/message_replies_widget.dart';
import 'package:taulight/widgets/tau_button.dart';

class NamedFileWrapper {
  final NamedFileDTO file;
  bool loaded = false;

  NamedFileWrapper(this.file);
}

class MessageField extends StatefulWidget {
  final TauChat chat;
  final List<ChatMessageWrapperDTO> replies;
  final List<NamedFileWrapper> files;
  final bool enabled;
  final FutureOr<void> Function(String) sendMessage;
  final FutureOr<void> Function() onFileAdd;

  const MessageField({
    super.key,
    required this.chat,
    required this.replies,
    required this.files,
    required this.enabled,
    required this.sendMessage,
    required this.onFileAdd,
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
            backgroundBuilder: (_, __, ___) => SizedBox.shrink(),
            key: UniqueKey(),
            direction: SwipeDirection.horizontal,
            child: ReplyPreviewWidget(chat: chat, reply: r),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.files.map((wrapper) {
              var file = wrapper.file;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: file.id != null
                            ? dark(getRandomColor(file.id!))
                            : Colors.black12,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: wrapper.loaded
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  file.filename,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  file.contentType,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withAlpha(160),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            ),
                    ),
                    if (wrapper.loaded)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => widget.files.remove(wrapper));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        if (enabled)
          Row(
            children: [
              TauButton.icon(
                Icons.add,
                color: Colors.blue,
                onPressed: widget.onFileAdd,
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
