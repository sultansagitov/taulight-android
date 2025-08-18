import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

class KeyDetailsScreen extends StatelessWidget {
  final String title;
  final Map<String, String> details;

  const KeyDetailsScreen({
    super.key,
    required this.title,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TauAppBar.text(title),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: details.entries
              .map((entry) => _buildDetailRow(context, entry.key, entry.value))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final labelColor = isDark ? Colors.grey[300]! : Colors.grey[800]!;
    final valueColor = isDark ? Colors.grey[200]! : Colors.grey[900]!;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final bgColor = isDark ? Colors.grey[850]! : Colors.grey[50]!;
    final iconColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: valueColor,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    snackBar(context, 'Copied: $value');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
