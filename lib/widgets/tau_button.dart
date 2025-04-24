import 'package:flutter/material.dart';

enum BtnStyle { text, button }

class TauButton extends StatelessWidget {
  final VoidCallback onPressed;
  final BtnStyle style;
  final String text;
  final bool loading;

  const TauButton(
    this.text, {
    super.key,
    required this.onPressed,
    this.style = BtnStyle.button,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: style == BtnStyle.text
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
            ),
          )
        : Text(text);

    if (style == BtnStyle.text) {
      return TextButton(
        onPressed: loading ? null : onPressed,
        style: ButtonStyle(
          enableFeedback: false,
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ButtonStyle(
        enableFeedback: false,
        shape: WidgetStateProperty.all(LinearBorder()),
      ),
      child: child,
    );
  }
}
