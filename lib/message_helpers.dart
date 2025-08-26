import 'package:flutter/cupertino.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform/codes.dart';
import 'package:taulight/widget_utils.dart';

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
