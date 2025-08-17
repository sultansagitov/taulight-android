import 'package:flutter/material.dart';
import 'package:taulight/widgets/tau_button.dart';

class WarningUnauthorizedMessage extends StatelessWidget {
  final String name;
  final VoidCallback onLoginTap;

  const WarningUnauthorizedMessage({
    super.key,
    required this.name,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: Colors.black, fontSize: 16);
    return Container(
      color: Colors.yellow[200],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.black),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: textStyle,
                ),
                Text(" not authenticated", style: textStyle),
              ],
            ),
          ),
          TauButton.text(
            "Login",
            color: Colors.black,
            style: BtnStyle.text,
            onPressed: onLoginTap,
          ),
        ],
      ),
    );
  }
}
