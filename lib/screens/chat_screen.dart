import 'package:flutter/material.dart';
import 'package:swipeable_tile/swipeable_tile.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/group_info_screen.dart';
import 'package:taulight/screens/member_info_screen.dart';
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
  List<ChatMessageWrapperDTO> replies = [];

  bool _loadingMessages = false;

  @override
  void initState() {
    super.initState();
    List<ChatMessageWrapperDTO> messages = widget.chat.messages;
    int? messagesTotalCount = widget.chat.totalCount;
    if (messages.isEmpty || messages.length != (messagesTotalCount ?? 0)) {
      _loadMessages(0, stateUpdate: false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void update() => setState(() {});

  Future<void> _loadMessages(int index, {bool stateUpdate = true}) async {
    if (widget.chat.client.connected) {
      if ((index + 20) > widget.chat.messages.length) {
        if (stateUpdate && mounted) setState(() => _loadingMessages = true);
        try {
          await widget.chat.loadMessages(index, 20);
        } finally {
          if (stateUpdate && mounted) setState(() => _loadingMessages = false);
        }
      }
    }

    if (index == 0) {
      setState(() {});
      widget.updateHome?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightMode = Theme.of(context).brightness == Brightness.light;
    final messages = widget.chat.messages;
    final messagesTotalCount = widget.chat.totalCount;

    final enabled = widget.chat.client.authorized;
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
                  ? MemberInfoScreen(
                      widget.chat.client,
                      (widget.chat.record as DialogDTO).otherNickname,
                    )
                  : GroupInfoScreen(
                      widget.chat,
                      updateHome: () {
                        setState(() {});
                        widget.updateHome?.call();
                      },
                    );

              await moveTo(context, screen);
              setState(() {});
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
                  itemCount: messages.length + (_loadingMessages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_loadingMessages && index == messages.length) {
                      // Show loading indicator at the end of the list
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    var rev = messages.reversed;
                    ChatMessageWrapperDTO? prev =
                        rev.elementAtOrNull(index + 1);
                    ChatMessageWrapperDTO? next;
                    if (index != 0) {
                      next = rev.elementAtOrNull(index - 1);
                    }

                    ChatMessageWrapperDTO message = rev.elementAt(index);

                    if (messages.length < (messagesTotalCount ?? 0)) {
                      if (index + 1 >= messages.length) {
                        Future.microtask(() async {
                          await _loadMessages(messages.length - 1);
                        });
                      }
                    }

                    if (!enabled) {
                      return MessageWidget(
                        chat: widget.chat,
                        message: message,
                        prev: prev,
                        next: next,
                      );
                    }

                    return buildMessage(message, prev, next);
                  },
                ),
              ),
            ] else if (_loadingMessages) ...[
              Expanded(
                child: Center(child: CircularProgressIndicator()),
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
              enabled: enabled,
              sendMessage: (text) async {
                var repliesUuid = replies.map((r) => r.view.id).toList();
                replies.clear();
                await widget.chat.sendMessage(text, repliesUuid, update);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessage(
    ChatMessageWrapperDTO message,
    ChatMessageWrapperDTO? prev,
    ChatMessageWrapperDTO? next,
  ) {
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
      backgroundBuilder: (_, direction, progress) => AnimatedBuilder(
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
      ),
      key: UniqueKey(),
      child: MessageWidget(
        chat: widget.chat,
        message: message,
        prev: prev,
        next: next,
      ),
    );
  }
}
