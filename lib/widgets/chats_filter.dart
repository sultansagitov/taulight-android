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

  Padding buildFilter(Filter filter) {
    bool selected = selectedFilters.contains(filter);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          selected
              ? selectedFilters.remove(filter)
              : selectedFilters.add(filter);

          widget.onChange(selectedFilters);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            filter.label,
            style: TextStyle(color: selected ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}
