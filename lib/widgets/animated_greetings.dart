import 'package:flutter/material.dart';
import 'package:taulight/config.dart';
import 'package:taulight/widgets/vertical_animated_text.dart';

class AnimatedGreeting extends StatelessWidget {
  final List<String> names;

  const AnimatedGreeting({super.key, required this.names});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final color = Config.primarySwatch[isLight ? 700 : 300];

    var s = TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 24);

    if (names.isEmpty) {
      return Text("Taulight", style: s);
    }

    return Row(
      children: [
        Text("Hi, ", style: s),
        Expanded(child: VerticalAnimatedText(texts: names, textStyle: s)),
      ],
    );
  }
}
