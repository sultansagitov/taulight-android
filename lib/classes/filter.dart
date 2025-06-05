import 'package:taulight/classes/tau_chat.dart';

class FilterManager {
  final List<Filter> filters = [];
}

abstract class Filter {
  final FilterManager manager;
  final String Function() label;
  final bool Function(TauChat) condition;

  bool _enabled = false;

  Filter(this.manager, this.label, this.condition) {
    manager.filters.add(this);
  }

  bool isEnabled() => _enabled;

  void enable() => _enabled = true;
  void disable() => _enabled = false;

  bool check(TauChat chat) => condition(chat);
}

class RadioFilter extends Filter {
  RadioFilter(super.manager, super.label, super.condition);

  @override
  void enable() {
    for (var filter in manager.filters) {
      filter.disable();
    }

    super.enable();
  }
}

class AnyFilter extends Filter {
  AnyFilter(super.manager, super.label, super.condition);

  @override
  bool check(TauChat chat) {
    for (var filter in manager.filters) {
      if (filter.isEnabled() && filter.condition(chat)) {
        return true;
      }
    }
    return false;
  }
}
