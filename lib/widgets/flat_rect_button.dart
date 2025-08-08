import 'package:flutter/material.dart';

class FlatRectButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final bool loading;
  final bool disable;

  const FlatRectButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.loading = false,
    this.disable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = backgroundColor ?? (isDark ? const Color(0xFF2F2F2F) : Colors.grey.shade200);
    final fgColor = foregroundColor ?? (isDark ? Colors.white : Colors.black);

    final isDisabled = disable || loading;

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1,
        child: Container(
          width: width,
          margin: margin,
          padding: padding ?? const EdgeInsets.all(14), // default chunky padding
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, color: fgColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
