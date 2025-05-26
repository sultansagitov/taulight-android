import 'package:flutter/material.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/avatar_service.dart';
import 'package:taulight/utils.dart';

class ChatAvatar extends StatefulWidget {
  final int d;
  final TauChat chat;

  ChatAvatar(this.chat, {required this.d}) : super(key: UniqueKey());

  @override
  State<ChatAvatar> createState() => _ChatAvatarState();
}

class _ChatAvatarState extends State<ChatAvatar> {
  late final Future<MemoryImage?> avatarFuture;

  @override
  void initState() {
    super.initState();

    avatarFuture = isChannel(widget.chat)
        ? AvatarService.ins.loadOrFetchChannelAvatar(widget.chat)
        : AvatarService.ins.loadOrFetchDialogAvatar(widget.chat);
  }

  @override
  Widget build(BuildContext context) {
    String initials = "";

    try {
      var title = widget.chat.record.getTitle();
      var split = title.split(" ");
      if (split.length >= 2) {
        initials = "";
        for (int i = 0; i < 2; i++) {
          initials += split[i][0];
        }
      } else {
        if (title.isNotEmpty) {
          initials = title[0];
          if (title.length > 1) {
            initials += title[1];
          }
        }
      }
    } catch (e) {
      initials = "??";
    }

    initials = initials.toUpperCase();

    Color bg = getRandomColor(widget.chat.record.getTitle());

    var decoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [bg, bg.withAlpha(200)],
      ),
    );

    var color = Colors.white.withAlpha(192);

    if (isDialog(widget.chat)) {
      return dialogAvatar(decoration, initials, color);
    }

    return channelAvatar(decoration, initials, color);
  }

  Widget channelAvatar(BoxDecoration decoration, String initials, Color color) {
    return FutureBuilder<MemoryImage?>(
      future: avatarFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            width: widget.d.toDouble(),
            height: widget.d.toDouble(),
            decoration: decoration.copyWith(shape: BoxShape.circle),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        return CircleAvatar(
          radius: widget.d / 2,
          backgroundImage: snapshot.data,
          backgroundColor: Colors.grey,
        );
      },
    );
  }

  Widget dialogAvatar(BoxDecoration decoration, String initials, Color color) {
    return FutureBuilder(
      future: avatarFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: widget.d.toDouble(),
              height: widget.d.toDouble(),
              decoration: decoration,
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: widget.d.toDouble(),
            height: widget.d.toDouble(),
            color: Colors.grey,
            child: Image.memory(
              snapshot.data!.bytes,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        );
      },
    );
  }
}
