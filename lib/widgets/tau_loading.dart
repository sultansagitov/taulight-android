import 'package:flutter/material.dart';

class TauLoading extends StatelessWidget {
  final Color? color;

  const TauLoading({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CircularProgressIndicator(
      color: color ?? (isDark ? Colors.grey[400]! : Colors.grey[700]!),
      strokeWidth: 2,
    );
  }
}
