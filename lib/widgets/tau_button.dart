import 'package:flutter/material.dart';
import 'package:taulight/widgets/tau_loading.dart';

enum BtnStyle { text, button }

class TauButton extends StatelessWidget {
  final VoidCallback onPressed;
  final BtnStyle style;
  final String? text;
  final IconData? icon;
  final bool loading;
  final bool disable;
  final Color? color;

  const TauButton._({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.style,
    required this.loading,
    required this.color,
    required this.disable,
  });

  factory TauButton.text(
    String text, {
    Key? key,
    required VoidCallback onPressed,
    BtnStyle style = BtnStyle.button,
    Color? color,
    bool loading = false,
    bool disable = false,
  }) =>
      TauButton._(
        key: key,
        text: text,
        icon: null,
        onPressed: onPressed,
        style: style,
        color: color,
        loading: loading,
        disable: disable,
      );

  factory TauButton.icon(
    IconData icon, {
    Key? key,
    required VoidCallback onPressed,
    BtnStyle style = BtnStyle.button,
    Color? color,
    bool loading = false,
    bool disable = false,
  }) =>
      TauButton._(
        key: key,
        text: null,
        icon: icon,
        onPressed: onPressed,
        style: style,
        color: color,
        loading: loading,
        disable: disable,
      );

  @override
  Widget build(BuildContext context) {
    final isText = text != null;

    final child = loading
        ? SizedBox(
            height: 16,
            width: 16,
            child: TauLoading(
              color: icon != null || style == BtnStyle.text
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
            ),
          )
        : isText
            ? Text(text!)
            : Icon(icon!);

    if (style == BtnStyle.text) {
      return TextButton(
        onPressed: loading || disable ? null : onPressed,
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
        onPressed: loading || disable ? null : onPressed,
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
      onPressed: loading || disable ? null : onPressed,
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
