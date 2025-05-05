import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/java_service.dart';

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
    if (isDialog(widget.chat)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: widget.d.toDouble(),
          height: widget.d.toDouble(),
          color: Colors.grey,
        ),
      );
    }

    return FutureBuilder<MemoryImage?>(
      future: avatarFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return CircleAvatar(
            radius: widget.d / 2,
            backgroundColor: Colors.grey,
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
