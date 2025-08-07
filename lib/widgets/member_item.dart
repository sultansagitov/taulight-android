import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/screens/profile.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';

class MemberItem extends StatelessWidget {
  final Client client;
  final int? d;
  final VoidCallback? onUpdated;

  const MemberItem({
    super.key,
    required this.client,
    this.d,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2F2F2F) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await moveTo(context, ProfileScreen(client));
        onUpdated?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MyAvatar(client: client, d: d ?? 52),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                client.user!.nickname,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
