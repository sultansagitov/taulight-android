import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform/chats.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

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
      appBar: TauAppBar.text("Send link to ..."),
      body: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final String nickname = (chat.record as DialogDTO).otherNickname;
          return _buildMember(nickname, chat, context);
        },
      ),
    );
  }

  Widget _buildMember(String nickname, TauChat chat, BuildContext context) {
    return InkWell(
      onTap: () async {
        if (nickname.isNotEmpty) {
          try {
            String code = await PlatformChatsService.ins
                .addMember(chatToInvite, nickname, Duration(days: 1));

            String address = chatToInvite.client.address;
            String text = "sandnode://$address/invite/$code";
            await chat.sendMessage(text, [], [], () {});

            if (context.mounted) {
              Navigator.pop(context);
            }
          } on NoEffectException {
            if (context.mounted) {
              snackBarError(context, "$nickname already in or have code");
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
            MemberAvatar(client: chat.client, nickname: nickname, d: 52),
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
  }
}
