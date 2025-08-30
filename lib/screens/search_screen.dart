import 'package:flutter/material.dart';
import 'package:taulight/widgets/chat_list.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

class SearchScreen extends StatefulWidget {
  final Key? chatKey;

  const SearchScreen({super.key, this.chatKey});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TauAppBar(
        title: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hint: Text(
              "  Search",
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          onChanged: (s) => setState(() {}),
        ),
      ),
      body: ChatList(
        filter: (chat) {
          final String query = normalize(controller.text);
          if (query.isEmpty) return true;

          final List<String> tokens = query.split(' ');

          if (matches(tokens, chat.record.getTitle())) return true;

          return chat.messages
              .any((msg) => matches(tokens, msg.decrypted ?? msg.view.text));
        },
        onChatTap: (chat) => Navigator.pop(context, chat),
      ),
    );
  }
}

String normalize(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool matches(List<String> tokens, String text) {
  final norm = normalize(text);
  return tokens.every((t) => norm.contains(t));
}
