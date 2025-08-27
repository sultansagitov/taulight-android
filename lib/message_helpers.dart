import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_message_wrapper_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/uuid.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/screens/member_info.dart';
import 'package:taulight/screens/profile.dart';
import 'package:taulight/services/platform/codes.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';

final RegExp urlRegExp = RegExp(
  r'(https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*))|'
  r'(sandnode:\/\/[^\/\s]+\/[a-zA-Z0-9/]+)',
  caseSensitive: false,
);

String? extractSandnodeUrl(String text) {
  final RegExp sandnodeRegExp = RegExp(
    r'sandnode://[^/\s]+/invite/[a-zA-Z0-9]+',
    caseSensitive: false,
  );
  final match = sandnodeRegExp.firstMatch(text);
  return match?.group(0);
}

List<T> parseMessage<T>({
  required String text,
  required T Function(String) regular,
  required T Function(String) sandnodeLink,
  required T Function(String) link,
}) {
  final List<T> result = [];
  int lastMatchEnd = 0;

  for (final match in urlRegExp.allMatches(text)) {
    final String url = match.group(0)!;
    final int start = match.start;
    final int end = match.end;

    if (start > lastMatchEnd) {
      result.add(regular(text.substring(lastMatchEnd, start)));
    }

    if (url.startsWith('sandnode://')) {
      result.add(sandnodeLink(url));
    } else {
      result.add(link(url));
    }

    lastMatchEnd = end;
  }

  if (lastMatchEnd < text.length) {
    result.add(regular(text.substring(lastMatchEnd)));
  }

  return result;
}

Future<void> sandnodeLinkPressed(
  BuildContext context,
  Client client,
  String url,
) async {
  final Uri uri = Uri.parse(url);
  final where = uri.path.split("/").where((s) => s.isNotEmpty);
  final code = [...where][1];

  String? error;

  try {
    await PlatformCodesService.ins.useCode(client, code);
  } on NotFoundException {
    error = "Code not found or not for you";
  } on NoEffectException {
    error = "Code used or expired";
  } on UnauthorizedException {
    error = "Code not for you";
  }

  if (context.mounted) {
    if (error != null) {
      snackBarError(context, error);
    } else {
      Navigator.pop(context);
    }
  }
}

void messageLongPress(
  BuildContext context,
  Client client,
  LongPressStartDetails details,
  ChatMessageWrapperDTO message,
) {
  final sent = message.view.id != UUID.nil;
  final hasDecryption = message.view.keyID == null;

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: MemberAvatar(
                client: client,
                nickname: message.view.nickname,
                d: 36,
              ),
              title: Text(
                message.decrypted ?? message.view.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () async {
                Navigator.pop(context);
                var sender = message.view.nickname;
                final screen = client.user?.nickname == sender
                    ? ProfileScreen(client)
                    : MemberInfoScreen(
                        client: client,
                        nickname: sender,
                        // TODO add fromDialog
                      );
                await moveTo(context, screen, fromBottom: true);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text("Copy text"),
              onTap: () {
                copy(context, message.decrypted ?? message.view.text);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(sent ? Icons.check_circle : Icons.access_time),
              title: Text(sent ? "Sent" : "Pending"),
            ),
            ListTile(
              leading: Icon(hasDecryption ? Icons.lock_open : Icons.lock),
              title: Text(hasDecryption ? "Decrypted" : "Encrypted"),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text("${message.view.dateTime.toLocal()}".split('.')[0]),
            ),
            const Divider(height: 1),
            if (sent)
              ListTile(
                leading: const Icon(Icons.numbers),
                title: Text.rich(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  TextSpan(
                    children: [
                      const TextSpan(text: "Copy ID  "),
                      TextSpan(
                        text: message.view.id.toString(),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  copy(context, message.view.id);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      );
    },
  );
}
