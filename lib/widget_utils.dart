import 'package:flutter/material.dart';
import 'package:taulight/widgets/preview_image.dart';

Future moveTo(
  BuildContext context,
  Widget screen, {
  bool fromLeft = false,
  bool fromBottom = false,
}) {
  return Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        final begin = fromBottom
            ? Offset(0, 1)
            : fromLeft
                ? Offset(-1, 0)
                : Offset(1, 0);
        const end = Offset.zero;
        final parent = CurveTween(curve: Curves.easeOutCubic);
        final chain = Tween(begin: begin, end: end).chain(parent);
        return SlideTransition(position: animation.drive(chain), child: child);
      },
    ),
  );
}

void snackBar(BuildContext context, String message) {
  print("Snack bar: $message");
  ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    duration: Duration(seconds: 1, milliseconds: 500),
  ));
}

void snackBarError(BuildContext context, String message) {
  print("Snack bar error: $message");
  ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message, style: TextStyle(color: Colors.white)),
    backgroundColor: Colors.red,
    duration: Duration(seconds: 1, milliseconds: 500),
  ));
}

Future<void> previewImage(BuildContext context, Image image) async {
  if (context.mounted) {
    await moveTo(context, PreviewImage(image), fromBottom: true);
  }
}
