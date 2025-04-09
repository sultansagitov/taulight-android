import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';

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

ImageProvider<Object> getImage(TauChat chat) {
  var seed = chat.id.hashCode % 100;
  var url = "https://randomuser.me/api/portraits/men/$seed.jpg";
  return NetworkImage(url);
}

Color getRandomColor(String seed) {
  var bytes = utf8.encode(seed);
  var digest = sha256.convert(bytes).bytes;

  int r = digest[0];
  int g = digest[1];
  int b = digest[2];

  List<int> rgb = [r, g, b];
  int maxChannel = rgb.reduce(max);
  if (maxChannel < 200) {
    double factor = 200 / maxChannel;
    r = (r * factor).clamp(0, 64).toInt();
    g = (g * factor).clamp(0, 64).toInt();
    b = (b * factor).clamp(0, 64).toInt();
  }

  return Color.fromARGB(255, r, g, b);
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

String parseSysMessages(TauChat chat, Message message) {
  String nickname = message.nickname;
  String text = message.text;
  List<String> split = text.split(".");

  if (split.length < 2) {
    return "$nickname: $text";
  }

  var type = split[0];
  var act = split[1];

  switch (type) {
    case 'channel':
      var channel = chat.record as ChannelRecord;
      switch (act) {
        case 'new':
          return 'Channel "${channel.title}" created by $nickname';
        case 'add':
          return '$nickname added to channel "${channel.title}"';
        case 'leave':
          return '$nickname left channel "${channel.title}"';
      }
    case 'dialog':
      switch (act) {
        case 'new':
          return 'New dialog started by $nickname';
      }
  }

  return "$nickname: $text";
}

String link2endpoint(String link) {
  var uri = Uri.parse(link);
  var endpoint = uri.host;
  if (uri.hasPort && uri.port == 52525) {
    endpoint += ":${uri.port}";
  }
  return endpoint;
}
