import 'package:flutter/material.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';

class DialogInfoScreen extends StatelessWidget {
  final TauChat chat;

  const DialogInfoScreen(this.chat, {super.key});

  @override
  Widget build(BuildContext context) {
    var record = chat.record as DialogRecord;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(width: 40, height: 40, color: Colors.black),
            ),
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
      body: Container(),
    );
  }

  Widget buildInfo(List<Member> members) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        "Members: ${members.length}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
