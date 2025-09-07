import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';

enum MessageDateOption { send, server }

class MessageTimeState {
  final MessageDateOption dateOption;
  MessageTimeState({required this.dateOption});
}

class MessageTimeNotifier extends StateNotifier<MessageTimeState> {
  MessageTimeNotifier()
      : super(MessageTimeState(dateOption: MessageDateOption.server));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = MessageTimeState(
      dateOption: MessageDateOption
          .values[prefs.getInt('dateOption') ?? MessageDateOption.server.index],
    );
  }

  Future<void> setDateOption(MessageDateOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dateOption', option.index);
    state = MessageTimeState(dateOption: option);
  }

  DateTime? getDate(ChatMessageViewDTO view) {
    return switch (state.dateOption) {
      MessageDateOption.send => view.sentDate,
      MessageDateOption.server => view.creationDate,
    };
  }
}

final messageTimeNotifierProvider =
    StateNotifierProvider<MessageTimeNotifier, MessageTimeState>(
  (ref) => MessageTimeNotifier(),
);
