import 'package:flutter/material.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/widget_utils.dart';

class MembersInviteScreen extends StatelessWidget {
  final List<TauChat> chats;
  final TauChat chatToInvite;

  const MembersInviteScreen({
    super.key,
    required this.chats,
    required this.chatToInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send link to ...")),
      body: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: chats.length,
          itemBuilder: (context, index) {
            var chat = chats[index];
            var d = 52;
            final String nickname = (chat.record as DialogDTO).otherNickname;

            return InkWell(
              onTap: () async {
                if (nickname.isNotEmpty) {
                  try {
                    String code = await chatToInvite.addMember(nickname, Duration(days: 1));

                    String endpoint = chatToInvite.client.endpoint;
                    String text = "sandnode://$endpoint/invite/$code";
                    await chat.sendMessage(text, [], () {});

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } on NoEffectException {
                    if (context.mounted) {
                      snackBarError(context, "$nickname already in");
                    }
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: d.toDouble(),
                        height: d.toDouble(),
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat.record.getTitle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
