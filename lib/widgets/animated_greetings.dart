import 'package:flutter/material.dart';

class AnimatedGreeting extends StatelessWidget {
  final List<String> names;

  const AnimatedGreeting({super.key, required this.names});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final color = Colors.deepOrange[isLight ? 700 : 300];

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 250,
        minWidth: 150,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "Hi, ",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 24,
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: StreamBuilder<int>(
              stream: Stream.periodic(
                const Duration(seconds: 2),
                (i) => i % names.length,
              ),
              initialData: 0,
              builder: (context, snapshot) {
                final name = names[snapshot.data ?? 0];
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    name,
                    key: ValueKey<String>(name),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
