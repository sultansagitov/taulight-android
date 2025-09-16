import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/screens/hub_info.dart';
import 'package:taulight/screens/login.dart';
import 'package:taulight/screens/profile.dart';
import 'package:taulight/services/client.dart';
import 'package:taulight/services/platform/agent.dart';
import 'package:taulight/services/storage.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/tau_button.dart';

class HubItem extends StatelessWidget {
  final Client client;
  final VoidCallback connectUpdate;

  const HubItem(this.client, this.connectUpdate, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = client.status;

    final Color cardBackground =
        isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final Color innerCardBackground =
        isDark ? const Color(0xFF2F2F2F) : Colors.grey.shade200;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    await moveTo(context, HubInfoScreen(client));
                    connectUpdate();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: innerCardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.str,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: status.color.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (client.user != null) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        await moveTo(context, ProfileScreen(client));
                        connectUpdate();
                      },
                      child: MyAvatar(client: client, d: 44),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TauButton.icon(
                  client.hide ? Icons.visibility : Icons.visibility_off,
                  disable: client.connected,
                  onPressed: () {
                    client.hide = !client.hide;
                    connectUpdate();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TauButton.icon(
                  Icons.refresh,
                  onPressed: () async {
                    try {
                      await client.reload();
                    } on ConnectionException {
                      if (context.mounted) {
                        snackBarError(
                            context, "Connection error: ${client.name}");
                      }
                    } finally {
                      connectUpdate();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildButton(context)),
              const SizedBox(width: 8),
              Expanded(
                child: TauButton.icon(
                  Icons.close,
                  onPressed: () async {
                    await client.disconnect();
                    await StorageService.ins.removeClient(client);
                    ClientService.ins.remove(client);
                    connectUpdate();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TauButton _buildButton(BuildContext context) {
    if (client.user == null || !client.user!.authorized) {
      return TauButton.icon(
        Icons.login,
        disable: !client.connected,
        onPressed: () async {
          final result = await moveTo(context, LoginScreen(client: client));
          if (result is String && result.contains("success")) {
            connectUpdate();
          }
        },
      );
    } else {
      return TauButton.icon(
        Icons.logout,
        disable: !client.connected,
        onPressed: () async {
          await PlatformAgentService.ins.logout(client);
          connectUpdate();
        },
      );
    }
  }
}
