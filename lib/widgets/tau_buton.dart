import 'package:flutter/material.dart';

enum BtnStyle { text, button }

class TauButton extends StatelessWidget {
  final VoidCallback onPressed;
  final BtnStyle style;
  final String text;

  const TauButton(
    this.text, {
    super.key,
    required this.onPressed,
    this.style = BtnStyle.button,
  });

  @override
  Widget build(BuildContext context) {
    if (style == BtnStyle.text) {
      return TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          enableFeedback: false,
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Text(text),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
          enableFeedback: false,
          shape: WidgetStateProperty.all(LinearBorder())),
      child: Text(text),
    );
  }
}
