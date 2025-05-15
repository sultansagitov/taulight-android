import 'package:flutter/material.dart';
import 'package:swipeable_tile/swipeable_tile.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/channel_info_screen.dart';
import 'package:taulight/screens/dialog_info_screen.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/message_widget.dart';
import 'package:taulight/widgets/message_field.dart';
import 'package:taulight/widgets/tau_button.dart';

class ChatScreen extends StatefulWidget {
  final TauChat chat;
  final VoidCallback? updateHome;

  const ChatScreen(
    this.chat, {
    super.key,
    this.updateHome,
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  List<ChatMessageViewDTO> replies = [];

  @override
  void initState() {
    super.initState();
    List<ChatMessageViewDTO> messages = widget.chat.messages;
    int? messagesTotalCount = widget.chat.totalCount;
    if (messages.isEmpty || messages.length != (messagesTotalCount ?? 0)) {
      _loadMessages(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void update() => setState(() {});

  Future<void> _loadMessages(int index) async {
    if (widget.chat.client.connected) {
      if ((index + 20) > widget.chat.messages.length) {
        await widget.chat.loadMessages(index, 20);
        setState(() {});
      }
    }

    if (index == 0) {
      widget.updateHome?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightMode = Theme.of(context).brightness == Brightness.light;
    final messages = widget.chat.messages;
    final messagesTotalCount = widget.chat.totalCount;

    var enabled = widget.chat.client.connected &&
        widget.chat.client.user != null &&
        widget.chat.client.user!.authorized;
    return Scaffold(
      appBar: AppBar(
        leading: TauButton.icon(
          Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            ChatAvatar(widget.chat, d: 36),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.chat.record.getTitle(),
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TauButton.icon(
            Icons.more_vert,
            onPressed: () async {
              Widget screen = isDialog(widget.chat)
                  ? DialogInfoScreen(widget.chat)
                  : ChannelInfoScreen(widget.chat);

              await moveTo(context, screen);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (messages.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var rev = messages.reversed;
                    ChatMessageViewDTO? prev = rev.elementAtOrNull(index + 1);
                    ChatMessageViewDTO? next;
                    if (index != 0) {
                      next = rev.elementAtOrNull(index - 1);
                    }

                    ChatMessageViewDTO message = rev.elementAt(index);

                    if (messages.length < (messagesTotalCount ?? 0)) {
                      if (index + 1 >= messages.length) {
                        _loadMessages(messages.length - 1);
                      }
                    }

                    if (!enabled) {
                      // Cannot swipe to reply
                      return MessageWidget(
                        chat: widget.chat,
                        message: message,
                        prev: prev,
                        next: next,
                      );
                    }

                    return SwipeableTile.swipeToTrigger(
                      behavior: HitTestBehavior.translucent,
                      isElevated: false,
                      color: Colors.transparent,
                      swipeThreshold: 0.2,
                      direction: SwipeDirection.endToStart,
                      onSwiped: (_) {
                        if (!replies.contains(message)) {
                          setState(() => replies.add(message));
                        }
                      },
                      backgroundBuilder: (_, direction, progress) {
                        return AnimatedBuilder(
                          animation: progress,
                          builder: (_, __) {
                            var tween = Tween<double>(begin: 0.0, end: 1.2);
                            var curvedAnimation = CurvedAnimation(
                              parent: progress,
                              curve: Interval(0.5, 1.0, curve: Curves.linear),
                            );
                            return Container(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Transform.scale(
                                  scale: tween.animate(curvedAnimation).value,
                                  child: Icon(Icons.reply),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      key: UniqueKey(),
                      child: MessageWidget(
                        chat: widget.chat,
                        message: message,
                        prev: prev,
                        next: next,
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Text(
                    "No messages",
                    style: TextStyle(color: Colors.grey[lightMode ? 600 : 400]),
                  ),
                ),
              ),
            ],
            MessageField(
              chat: widget.chat,
              replies: replies,
              sendMessage: enabled
                  ? (text) {
                      var repliesUuid = replies.map((r) => r.id).toList();
                      replies.clear();
                      widget.chat.sendMessage(text, repliesUuid, update);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
