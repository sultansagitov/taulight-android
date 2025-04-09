import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taulight/classes/client.dart';

Future<dynamic> moveTo(BuildContext context, Widget screen) {
  return Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1, 0);
        const end = Offset.zero;
        final parent = CurveTween(curve: Curves.easeOutCubic);
        final chain = Tween(begin: begin, end: end).chain(parent);
        return SlideTransition(position: animation.drive(chain), child: child);
      },
    ),
  );
}

Future openHubDialog(BuildContext context, Client client) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.all(12),
      shape: LinearBorder(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            client.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16),
          ),
          Text(client.status),
          _info(context, "Hub name", client.name),
          _info(context, "Hub link", client.link),
        ],
      ),
    ),
  );
}

Widget _info(BuildContext context, String key, String value) {
  bool isLight = Theme.of(context).brightness == Brightness.light;
  return GestureDetector(
    onLongPress: () {
      Clipboard.setData(ClipboardData(text: value));
      snackBar(context, "$key copied");
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "$key: $value",
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
          style: TextStyle(color: isLight ? Colors.black : Colors.white),
        ),
      ),
    ),
  );
}

void snackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: Duration(seconds: 1, milliseconds: 500),
  ));
}
