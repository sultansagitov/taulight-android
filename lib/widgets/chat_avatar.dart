import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/java_service.dart';
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

    final client = widget.chat.client;

    if (isChannel(widget.chat)) {
      final channel = widget.chat.record as ChannelDTO;
      avatarFuture = _loadOrFetchChannelAvatar(client, channel.id);
    } else {
      avatarFuture = Future.value(null);
    }
  }

  Future<MemoryImage> _loadOrFetchChannelAvatar(
    Client client,
    String channelId,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/avatar_${client.uuid}_$channelId.png';
    final file = File(filePath);

    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      return MemoryImage(bytes);
    } else {
      var channel = widget.chat.record as ChannelDTO;
      final map = await JavaService.instance.getChannelAvatar(client, channel);
      final base64Str = map["imageBase64"];
      if (base64Str == null) {
        throw Exception("No image returned");
      }
      final bytes = base64Decode(base64Str);
      await file.writeAsBytes(bytes, flush: true);
      return MemoryImage(bytes);
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
    var color = (bg.r + bg.g * 2 + bg.b) > 2
        ? Colors.black.withAlpha(224)
        : Colors.white.withAlpha(192);

    if (isDialog(widget.chat)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: widget.d.toDouble(),
          height: widget.d.toDouble(),
          color: bg,
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
          return CircleAvatar(
            radius: widget.d / 2,
            backgroundColor: bg,
            child: Text(initials, style: TextStyle(color: color)),
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
