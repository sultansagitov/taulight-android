import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/screens/chat.dart';
import 'package:taulight/screens/member_qr.dart';
import 'package:taulight/screens/qr_exchange.dart';
import 'package:taulight/services/platform/chats.dart';
import 'package:taulight/services/profile_avatar.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

class MemberInfoScreen extends StatelessWidget {
  final Client client;
  final String nickname;
  final bool fromDialog;

  const MemberInfoScreen({
    super.key,
    required this.client,
    required this.nickname,
    this.fromDialog = true,
  });

  Future<void> _previewImage(BuildContext context) async {
    final memoryImage = await ProfileAvatarService.ins.getOf(client, nickname);
    if (memoryImage == null) return;

    final image = Image.memory(memoryImage.bytes, fit: BoxFit.contain);

    await previewImage(context, image);
  }

  Future<void> _message(BuildContext context) async {
    TauChat? chat;

    for (final c in client.chats.values) {
      final record = c.record;
      if (record is DialogDTO && record.otherNickname == nickname) {
        chat = c;
        break;
      }
    }

    chat ??= await PlatformChatsService.ins.createDialog(client, nickname);

    await moveTo(context, ChatScreen(chat));
  }

  Future<void> _qr(BuildContext context) async {
    await moveTo(context, MemberQRScreen(client: client, nickname: nickname));
  }

  Future<void> _exchange(BuildContext context) async {
    await moveTo(context, QRExchangeScreen(client: client, other: nickname));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              nickname,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (fromDialog)
                _buildButton(
                  icon: Icons.message,
                  title: "Message",
                  onPressed: () => _message(context),
                )
              else
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.message,
                        color: theme.iconTheme.color?.withValues(alpha: .5),
                      ),
                      SizedBox(width: 16),
                      Text(
                        "Go back to message",
                        style: TextStyle(
                          color: theme.textTheme.titleMedium?.color
                              ?.withValues(alpha: .5),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildButton(
                icon: Icons.qr_code,
                title: "Show QR for third person",
                onPressed: () => _qr(context),
              ),
              _buildButton(
                icon: Icons.key_outlined,
                title: "Check encryption",
                onPressed: () => _exchange(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String title,
    required Future<void> Function() onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Text(title),
          ],
        ),
      ),
    );
  }
}
