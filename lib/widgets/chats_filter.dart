import 'package:flutter/material.dart';
import 'package:taulight/classes/tau_chat.dart';

class Filter {
  final String label;
  final bool Function(TauChat) condition;

  Filter(this.label, this.condition);
}

class ChatsFilter extends StatefulWidget {
  final List<Filter> filters;
  final Set<Filter> initial;
  final void Function(Set<Filter> selectedFilters) onChange;

  const ChatsFilter({
    super.key,
    required this.filters,
    required this.onChange,
    required this.initial,
  });

  @override
  State<ChatsFilter> createState() => _ChatsFilterState();
}

class _ChatsFilterState extends State<ChatsFilter> {
  late final Set<Filter> selectedFilters;

  @override
  void initState() {
    super.initState();
    setState(() => selectedFilters = widget.initial);
  }

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
    bool selected = selectedFilters.contains(filter);
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
            selected
                ? selectedFilters.remove(filter)
                : selectedFilters.add(filter);
          });
          widget.onChange(selectedFilters);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? selectedColor : unselectedColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            filter.label,
            style: TextStyle(
              color: selected ? selectedTextColor : unselectedTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
