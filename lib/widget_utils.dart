import 'package:flutter/material.dart';
import 'package:taulight/widgets/preview_image.dart';

Future moveTo(
  BuildContext context,
  Widget screen, {
  bool fromLeft = false,
  bool fromBottom = false,
  bool canReturn = true,
}) {
  final route = PageRouteBuilder(
    pageBuilder: (_, __, ___) => screen,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, __, child) {
      final begin = fromBottom
          ? const Offset(0, 1)
          : fromLeft
              ? const Offset(-1, 0)
              : const Offset(1, 0);
      const end = Offset.zero;
      final parent = CurveTween(curve: Curves.easeOutCubic);
      final chain = Tween(begin: begin, end: end).chain(parent);
      return SlideTransition(position: animation.drive(chain), child: child);
    },
  );

  return canReturn
      ? Navigator.push(context, route)
      : Navigator.pushReplacement(context, route);
}

void snackBar(BuildContext context, String message) {
  print("Snack bar: $message");
  ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 1, milliseconds: 500),
  ));
}

void snackBarError(BuildContext context, String message) {
  print("Snack bar error: $message");
  ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message, style: const TextStyle(color: Colors.white)),
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 1, milliseconds: 500),
  ));
}

Future<void> previewImage(BuildContext context, Image image) async {
  if (context.mounted) {
    await moveTo(context, PreviewImage(image), fromBottom: true);
  }
}
