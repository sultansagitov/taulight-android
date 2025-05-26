import 'package:flutter/material.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/client_service.dart';
import 'package:taulight/widgets/chat_item.dart';
import 'package:taulight/widgets/chats_filter.dart';
import 'package:taulight/widgets/warning_disconnect_message.dart';
import 'package:taulight/widgets/warning_unauthorized_message.dart';

class ChatList extends StatefulWidget {
  final VoidCallback updateHome;
  final Future<void> Function(TauChat chat) onChatTap;
  final Future<void> Function(Client client) onLoginTap;

  const ChatList({
    super.key,
    required this.updateHome,
    required this.onChatTap,
    required this.onLoginTap,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final List<Filter> filters = [
    Filter(() => 'Channels', isChannel),
    Filter(() => 'Dialogs', isDialog),
  ];

  Set<Filter> selectedFilters = {};

  @override
  Widget build(BuildContext context) {
    var clients = ClientService.ins.clientsList;

    // Collect all disconnected (but not hidden) hubs
    var disconnectedHubs =
        clients.where((c) => !c.connected && !c.hide).toList();

    // Collect all connected but unauthorized hubs
    var unauthorizedHubs = clients
        .where((c) => c.connected && (c.user == null || !c.user!.authorized))
        .toList();

    // Collect all chats from clients that have a valid user
    List<TauChat> chats =
        clients.expand((client) => client.chats.values).where((chat) {
      if (selectedFilters.isEmpty) {
        return true;
      }

      for (Filter filter in selectedFilters) {
        if (!filter.condition(chat)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort chats:
    // - chats with messages come first
    // - newest messages go to the top
    chats.sort((a, b) {
      if (a.messages.isEmpty) return 1;
      if (b.messages.isEmpty) return -1;
      return b.messages.last.view.dateTime
          .compareTo(a.messages.last.view.dateTime);
    });

    List<Widget> list = [];

    for (Client client in disconnectedHubs) {
      list.add(WarningDisconnectMessage(
        client: client,
        updateHome: widget.updateHome,
      ));
    }

    for (Client client in unauthorizedHubs) {
      list.add(WarningUnauthorizedMessage(
        name: client.name,
        onLoginTap: () => widget.onLoginTap(client),
      ));
    }

    var c = clients.where((c) => c.authorized);
    Iterable<Filter> clientFilter = c.length != 1 ? c.map((c) => c.filter) : [];
    list.add(ChatsFilter(
      filters: [...filters, ...clientFilter],
      initial: selectedFilters,
      onChange: (selected) => setState(() => selectedFilters = selected),
    ));

    if (chats.isNotEmpty) {
      list.addAll(chats.map((chat) {
        return ChatItem(
          key: ValueKey(chat.record.id),
          chat: chat,
          onTap: widget.onChatTap,
        );
      }));
    } else {
      list.add(const Center(
        child: SizedBox(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                "No chats found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                "Try adjusting your filters",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ));
    }

    // Build the list of widgets for the UI
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => list[i],
    );
  }
}
