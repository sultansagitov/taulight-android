import 'package:flutter/material.dart';
import 'package:taulight/classes/code_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/invite_service.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';

class InviteWidget extends StatefulWidget {
  final TauChat chat;
  final String url;

  const InviteWidget(this.chat, this.url, {super.key});

  @override
  State<InviteWidget> createState() => _InviteWidgetState();
}

class _InviteWidgetState extends State<InviteWidget> {
  Future<CodeDTO>? inviteDetails;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;
    final Uri uri = Uri.parse(widget.url);
    var where = uri.path.split("/").where((s) => s.isNotEmpty);
    var codeString = where.elementAt(1);

    return FutureBuilder(
      future: inviteDetails ??= InviteService.ins
          .checkCode(widget.chat.client, codeString)
          .timeout(Duration(seconds: 5)),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Error when loading invite ${snapshot.error}");
        }

        var code = snapshot.data;
        if (code == null) {
          return Container();
        }

        final initials = getInitials(code.title);
        final bg = getRandomColor(code.title);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                GroupInitials(
                  initials: initials,
                  bgColor: bg,
                  d: 40,
                ),
                const SizedBox(width: 12),
                Text(
                  code.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor.withAlpha(180),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'From: ${code.sender}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: textColor.withAlpha(180)),
            ),
            const SizedBox(height: 4),
            if (code.activation == null)
              Row(
                children: [
                  Icon(
                    code.isExpired ? Icons.timer_off : Icons.timer,
                    size: 14,
                    color: code.isExpired ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${formatFutureTime(code.expires.toLocal())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: code.isExpired ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (code.activation != null) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Activated: ${formatTime(code.activation!.toLocal())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            if (code.isExpired && code.activation == null) ...[
              Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Invitation expired',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
