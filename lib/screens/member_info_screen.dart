import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/screens/chat_screen.dart';
import 'package:taulight/services/platform_chats_service.dart';
import 'package:taulight/services/profile_avatar_service.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
import 'package:taulight/widgets/tau_button.dart';

class MemberInfoScreen extends StatelessWidget {
  final Client client;
  final String nickname;

  const MemberInfoScreen(this.client, this.nickname, {super.key});

  Future<void> _previewImage(BuildContext context) async {
    var memoryImage = await ProfileAvatarService.ins.getOf(client, nickname);
    if (memoryImage == null) return;

    var image = Image.memory(memoryImage.bytes, fit: BoxFit.contain);

    await previewImage(context, image);
  }

  Future<void> _message(BuildContext context) async {
    TauChat? chat;

    for (var c in client.chats.values) {
      var record = c.record;
      if (record is DialogDTO && record.otherNickname == nickname) {
        chat = c;
        break;
      }
    }

    chat ??= await PlatformChatsService.ins.createDialog(client, nickname);

    await moveTo(context, ChatScreen(chat));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TauAppBar.empty(),
      body: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _previewImage(context),
              child: MemberAvatar(client: client, nickname: nickname, d: 200),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nickname,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TauButton.icon(Icons.message, onPressed: () => _message(context)),
        ],
      ),
    );
  }
}
