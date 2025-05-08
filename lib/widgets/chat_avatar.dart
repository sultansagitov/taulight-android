import 'package:flutter/material.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/avatar_service.dart';
import 'package:taulight/utils.dart';

class ChatAvatar extends StatefulWidget {
  final int d;
  final TauChat chat;

  const ChatAvatar(this.chat, {super.key, required this.d});

  @override
  State<ChatAvatar> createState() => _ChatAvatarState();
}

class _ChatAvatarState extends State<ChatAvatar> {
  late final Future<MemoryImage?> avatarFuture;

  @override
  void initState() {
    super.initState();

    if (isChannel(widget.chat)) {
      final channel = widget.chat.record as ChannelDTO;
      avatarFuture = AvatarService.instance
          .loadOrFetchChannelAvatar(widget.chat, channel.id);
    } else {
      avatarFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    String initials = "";

    try {
      var title = widget.chat.getTitle();
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

    Color bg = getRandomColor(widget.chat.id);

    var decoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [bg, bg.withAlpha(200)],
      ),
    );

    var color = Colors.white.withAlpha(192);

    if (isDialog(widget.chat)) {
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
}
