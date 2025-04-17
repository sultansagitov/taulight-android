import 'package:flutter/material.dart';
import 'package:swipeable_tile/swipeable_tile.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/channel_info_screen.dart';
import 'package:taulight/screens/dialog_info_screen.dart';
import 'package:taulight/widgets/message_widget.dart';
import 'package:taulight/widgets/message_field.dart';

class ChatScreen extends StatefulWidget {
  final TauChat chat;
  final VoidCallback? updateHome;

  const ChatScreen({
    super.key,
    required this.chat,
    this.updateHome
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
      if (widget.updateHome != null) widget.updateHome!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightMode = Theme.of(context).brightness == Brightness.light;
    final messages = widget.chat.messages;
    final messagesTotalCount = widget.chat.totalCount;

    final isDialog = widget.chat.record is DialogDTO;
    var d = 36;

    var enabled = widget.chat.client.connected &&
        widget.chat.client.user != null &&
        widget.chat.client.user!.authorized;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            if (isDialog) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: d.toDouble(),
                  height: d.toDouble(),
                  color: Colors.black,
                ),
              ),
            ] else ...[
              CircleAvatar(
                radius: d / 2,
                // backgroundImage: getImage(chat),
                backgroundColor: Colors.black,
              ),
            ],
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.chat.getTitle(),
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              if (widget.chat.record is DialogDTO) {
                moveTo(context, DialogInfoScreen(widget.chat));
              } else {
                moveTo(context, ChannelInfoScreen(widget.chat));
              }
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
