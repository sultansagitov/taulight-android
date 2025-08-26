import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime_type/mime_type.dart';
import 'package:swipeable_tile/swipeable_tile.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/screens/profile.dart';
import 'package:taulight/services/file_messages.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/group_info.dart';
import 'package:taulight/screens/member_info.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/message.dart';
import 'package:taulight/widgets/message_field.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
import 'package:taulight/widgets/tau_button.dart';
import 'package:taulight/widgets/tau_loading.dart';

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
  final List<ChatMessageWrapperDTO> replies = [];
  final List<NamedFileWrapper> files = [];

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

  Future<void> _onFileAdd() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result == null) {
      return;
    }

    result.files;
    await Future.wait(result.files.map((file) async {
      final path = file.path!;

      final chat = widget.chat;
      final contentType =
          mimeFromExtension(path.split(".").last) ?? "text/plain";
      final filename = path.split(Platform.pathSeparator).last;

      final dto = NamedFileDTO(null, contentType, filename);
      final wrapper = NamedFileWrapper(dto);

      setState(() => files.add(wrapper));

      final id = await FileMessageService.ins.uploadFile(chat, path, filename);

      setState(() {
        wrapper.loaded = true;
        dto.id = id;
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    final lightMode = Theme.of(context).brightness == Brightness.light;
    final messages = widget.chat.messages;
    final messagesTotalCount = widget.chat.totalCount;

    final enabled = widget.chat.client.authorized;
    return Scaffold(
      appBar: TauAppBar.icon(
        ChatAvatar(widget.chat, d: 48),
        widget.chat.record.getTitle(),
        actions: [
          TauButton.icon(
            Icons.more_vert,
            onPressed: () async {
              final chat = widget.chat;
              final client = chat.client;

              Widget screen;

              if (isDialog(chat)) {
                final dialog = chat.record as DialogDTO;
                final otherNickname = dialog.otherNickname;

                if (client.user!.nickname == otherNickname) {
                  screen = ProfileScreen(client);
                } else {
                  screen = MemberInfoScreen(
                    client: client,
                    nickname: otherNickname,
                    fromDialog: false,
                  );
                }
              } else {
                screen = GroupInfoScreen(chat, updateHome: () {
                  setState(() {});
                  widget.updateHome?.call();
                });
              }

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
                        child: Center(child: TauLoading()),
                      );
                    }

                    final rev = messages.reversed;
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
              const Expanded(child: Center(child: TauLoading())),
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
              files: files,
              enabled: enabled,
              onFileAdd: _onFileAdd,
              sendMessage: (text) async {
                final r = replies.map((r) => r.view.id).toList();
                final f = files.map((w) => w.file).toList();

                replies.clear();
                files.clear();

                await widget.chat.sendMessage(text, r, f, update);
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
      key: UniqueKey(),
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
          final tween = Tween<double>(begin: 0.0, end: 1.2);
          final curvedAnimation = CurvedAnimation(
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
      child: MessageWidget(
        chat: widget.chat,
        message: message,
        prev: prev,
        next: next,
      ),
    );
  }
}
