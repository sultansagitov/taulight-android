import 'package:flutter/material.dart';

class Tip extends StatelessWidget {
  final String message;

  const Tip(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final normalized = message.trim().replaceAll(RegExp(r'\s+'), ' ');
    final regex = RegExp(r'not secure', caseSensitive: false);

    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in regex.allMatches(normalized)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: normalized.substring(lastIndex, match.start)));
      }

      spans.add(const TextSpan(
        text: "not secure",
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < normalized.length) {
      spans.add(TextSpan(text: normalized.substring(lastIndex)));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: Colors.grey.withAlpha(64),
        padding: const EdgeInsets.all(8.0),
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 11),
            children: spans,
          ),
        ),
      ),
    );
  }
}
