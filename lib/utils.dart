import 'dart:math';
import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/tau_chat.dart';

import 'classes/chat_message_wrapper_dto.dart';

String formatTime(DateTime dateTime) {
  DateTime now = DateTime.now();

  if (dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day) {
    return formatOnlyTime(dateTime);
  }

  DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

  if (dateTime.isAfter(startOfWeek) && dateTime.isBefore(endOfWeek)) {
    return weekdays[dateTime.weekday - 1];
  }

  return '${months[dateTime.month - 1]} ${dateTime.day}';
}

String? formatFutureTime(DateTime dateTime) {
  DateTime now = DateTime.now();

  if (dateTime.isBefore(now)) {
    return null;
  }

  Duration difference = dateTime.difference(now);
  String remainingTime = '${difference.inDays}:'
      '${difference.inHours % 24}:'
      '${difference.inMinutes % 60}';

  return remainingTime;
}

String formatOnlyTime(DateTime dateTime) {
  return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
}

List<String> weekdays = 'Mon Tue Wed Thu Fri Sat Sun'.split(' ');

List<String> months =
    'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec'.split(' ');

Color getRandomColor(String seed) {
  int hash = seed.codeUnits.fold(0, (prev, elem) => prev + elem);
  final Random random = Random(hash);

  final double hue = random.nextDouble() * 360;
  final double saturation = 0.4 + random.nextDouble() * 0.2;
  final double lightness = 0.5 + random.nextDouble() * 0.1;

  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}

String getInitials(String title) {
  String initials = "";

  try {
    var split = title.split(" ");
    if (split.length >= 2) {
      initials = "";
      for (int i = 0; i < 2; i++) {
        initials += split[i][0];
      }
    } else {
      if (title.isNotEmpty) {
        initials = title[0];
        if (title.length > 1) {
          initials += title[1];
        }
      }
    }
  } catch (e, stackTrace) {
    print(e);
    print(stackTrace);
    initials = "??";
  }

  initials = initials.toUpperCase();
  return initials;
}

Color grey(Color color) {
  var avg = ((color.r + color.g + color.b) * 255 / 3).round();
  return Color.fromRGBO(avg, avg, avg, 1.0);
}

Color dark(Color color) {
  return Color.fromRGBO(
    (pow(color.r * 0.8, 2) * 255).round(),
    (pow(color.g * 0.8, 2) * 255).round(),
    (pow(color.b * 0.8, 2) * 255).round(),
    1.0,
  );
}

String parseSysMessages(TauChat chat, ChatMessageWrapperDTO message) {
  String nickname = message.view.nickname.trim();
  String text = message.decrypted!.trim();
  List<String> split = text.split(".");

  if (split.length < 2) {
    return "$nickname: $text";
  }

  var type = split[0];
  var act = split[1];

  switch (type) {
    case 'group':
      var group = chat.record as GroupDTO;
      switch (act) {
        case 'new':
          return 'Group "${group.title}" created by $nickname';
        case 'add':
          return '$nickname added to group "${group.title}"';
        case 'leave':
          return '$nickname left group "${group.title}"';
      }
    case 'dialog':
      var dialog = chat.record as DialogDTO;
      if (!dialog.isMonolog) {
        switch (act) {
          case 'new':
            return 'New dialog started by $nickname';
        }
      } else {
        switch (act) {
          case 'new':
            return 'Monolog started';
        }
      }
  }

  return "$nickname: $text";
}

String link2address(String link) {
  var uri = Uri.parse(link);
  var address = uri.host;
  if (uri.hasPort && uri.port == 52525) {
    address += ":${uri.port}";
  }
  return address;
}
