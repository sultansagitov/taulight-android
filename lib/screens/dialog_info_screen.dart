import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_member.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/widgets/chat_avatar.dart';

class DialogInfoScreen extends StatelessWidget {
  final TauChat chat;

  const DialogInfoScreen(this.chat, {super.key});

  @override
  Widget build(BuildContext context) {
    var record = chat.record as DialogDTO;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ChatAvatar(chat, d: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                record.otherNickname,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: SizedBox.shrink(),
    );
  }

  Widget buildInfo(List<ChatMember> members) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        "Members: ${members.length}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
