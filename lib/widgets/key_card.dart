import 'package:flutter/material.dart';

class KeyCard extends StatelessWidget {
  final String? title;
  final String subtitle;
  final List<String> details;
  final VoidCallback onTap;

  const KeyCard({
    super.key,
    this.title,
    required this.subtitle,
    required this.details,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? Colors.grey[900]! : Colors.grey[50]!;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final textColor = isDark ? Colors.grey[200]! : Colors.grey[800]!;
    final secondaryText = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 6),
                  ...details.map(
                    (detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        detail,
                        style: TextStyle(color: secondaryText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.visibility, color: secondaryText),
              onPressed: onTap,
              tooltip: 'View Details',
            ),
          ],
        ),
      ),
    );
  }
}
