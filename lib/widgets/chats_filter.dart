import 'package:flutter/material.dart';
import 'package:taulight/classes/filter.dart';

class ChatsFilter extends StatefulWidget {
  final List<Filter> filters;
  final void Function() onChange;

  const ChatsFilter({
    super.key,
    required this.filters,
    required this.onChange,
  });

  @override
  State<ChatsFilter> createState() => _ChatsFilterState();
}

class _ChatsFilterState extends State<ChatsFilter> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: widget.filters.map(buildFilter).toList()),
      ),
    );
  }

  Widget buildFilter(Filter filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedColor = isDark ? Colors.blue[300]! : Colors.blue;
    final unselectedColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final selectedTextColor = isDark ? Colors.black : Colors.white;
    final unselectedTextColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (filter.isEnabled()) {
              filter.disable();
            } else {
              filter.enable();
            }
          });
          widget.onChange();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: filter.isEnabled() ? selectedColor : unselectedColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: 180),
            child: Text(
              filter.label(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: filter.isEnabled()
                    ? selectedTextColor
                    : unselectedTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
