import 'package:flutter/material.dart';

class Tip extends StatelessWidget {
  final String message;

  const Tip(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(10),
      child: Container(
        color: Colors.grey.withAlpha(64),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(message),
        ),
      ),
    );
  }
}
