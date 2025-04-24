import 'package:flutter/material.dart';

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

void snackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: Duration(seconds: 1, milliseconds: 500),
  ));
}
