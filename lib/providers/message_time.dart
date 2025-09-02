import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';

enum MessageDateOption { send, server }

// TODO
class MessageTimeProvider extends ChangeNotifier {
  MessageDateOption _dateOption = MessageDateOption.server;

  MessageDateOption get dateOption => _dateOption;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _dateOption = MessageDateOption
        .values[prefs.getInt('dateOption') ?? MessageDateOption.server.index];
    notifyListeners();
  }

  Future<void> setDateOption(MessageDateOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dateOption', option.index);
    _dateOption = option;
    notifyListeners();
  }

  DateTime getDate(ChatMessageViewDTO view) {
    switch (dateOption) {
      case MessageDateOption.send:
        return view.sentDate;
      case MessageDateOption.server:
        return view.creationDate;
    }
  }
}
