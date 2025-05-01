import 'package:flutter/material.dart';

enum BtnStyle { text, button }

class TauButton extends StatelessWidget {
  final VoidCallback onPressed;
  final BtnStyle style;
  final String? text;
  final IconData? icon;
  final bool loading;
  final Color? color;

  factory TauButton.text(
    String text, {
    Key? key,
    required VoidCallback onPressed,
    BtnStyle style = BtnStyle.button,
    Color? color,
    bool loading = false,
  }) =>
      TauButton._(
        key: key,
        text: text,
        icon: null,
        onPressed: onPressed,
        style: style,
        color: color,
        loading: loading,
      );

  factory TauButton.icon(
    IconData icon, {
    Key? key,
    required VoidCallback onPressed,
    BtnStyle style = BtnStyle.button,
    Color? color,
    bool loading = false,
  }) =>
      TauButton._(
        key: key,
        text: null,
        icon: icon,
        onPressed: onPressed,
        style: style,
        color: color,
        loading: loading,
      );

  const TauButton._({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.style,
    required this.loading,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isText = text != null;

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
        : isText
            ? Text(text!)
            : Icon(icon!);

    if (style == BtnStyle.text) {
      return TextButton(
        onPressed: loading ? null : onPressed,
        style: ButtonStyle(
          enableFeedback: false,
          foregroundColor: WidgetStateProperty.all(color),
          iconColor: WidgetStateProperty.all(color),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: child,
      );
    }
    if (isText) {
      return ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ButtonStyle(
          enableFeedback: false,
          foregroundColor: WidgetStateProperty.all(color),
          iconColor: WidgetStateProperty.all(color),
          shape: WidgetStateProperty.all(LinearBorder()),
        ),
        child: child,
      );
    }

    return IconButton(
      onPressed: loading ? null : onPressed,
      style: ButtonStyle(
        enableFeedback: false,
        foregroundColor: WidgetStateProperty.all(color),
        iconColor: WidgetStateProperty.all(color),
        shape: WidgetStateProperty.all(LinearBorder()),
      ),
      icon: child,
    );
  }
}
