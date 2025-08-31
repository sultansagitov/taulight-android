import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MessageDateOption { send, server }

// TODO
class MessageTimeProvider extends ChangeNotifier {
  MessageDateOption _dateOption = MessageDateOption.send;

  MessageDateOption get dateOption => _dateOption;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _dateOption = MessageDateOption
        .values[prefs.getInt('dateOption') ?? MessageDateOption.send.index];
    notifyListeners();
  }

  Future<void> setDateOption(MessageDateOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dateOption', option.index);
    _dateOption = option;
    notifyListeners();
  }
}
