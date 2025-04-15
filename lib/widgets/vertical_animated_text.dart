import 'dart:async';

import 'package:flutter/material.dart';

class VerticalAnimatedText extends StatefulWidget {
  final Alignment _alignment;
  final List<String> texts;
  final TextStyle? textStyle;

  const VerticalAnimatedText({
    super.key,
    required this.textStyle,
    required this.texts,
    Alignment? alignment,
  }) : _alignment = alignment ?? Alignment.centerLeft;

  @override
  State<VerticalAnimatedText> createState() => _VerticalAnimatedTextState();
}

class _VerticalAnimatedTextState extends State<VerticalAnimatedText> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTextChangeTimer();
  }

  void _startTextChangeTimer() {
    Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() => _index = ((_index + 1) % widget.texts.length).round());
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        bool movingForward = animation.status != AnimationStatus.completed;

        var slideAnim = Tween<Offset>(
          begin: Offset(0, movingForward ? -0.5 : 0.5),
          end: Offset.zero,
        ).animate(animation);

        var fadeAnim = Tween<double>(begin: -0.5, end: 1).animate(animation);

        return Align(
          alignment: widget._alignment,
          child: SlideTransition(
            position: slideAnim,
            child: Align(
              alignment: widget._alignment,
              child: FadeTransition(opacity: fadeAnim, child: child),
            ),
          ),
        );
      },
      child: Text(
        widget.texts[_index],
        key: ValueKey<int>(_index),
        style: widget.textStyle,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
