import 'package:flutter/material.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/menus/home.dart';
import 'package:taulight/start_method.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/method_call_handler.dart';
import 'package:taulight/screens/chat_screen.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/widgets/animated_greetings.dart';
import 'package:taulight/widgets/chat_item.dart';
import 'package:taulight/screens/login_screen.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/widgets/chats_filter.dart';
import 'package:taulight/widgets/no_chats.dart';
import 'package:taulight/widgets/not_logged_in.dart';

import 'package:taulight/widgets/hubs_empty.dart';
import 'package:taulight/widgets/tau_button.dart';
import 'package:taulight/widgets/warning_disconnect_message.dart';
import 'package:taulight/widgets/warning_unauthorized_message.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen() : super(key: GlobalKey<HomeScreenState>());

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final chatKey = GlobalKey<ChatScreenState>();
  late final MethodCallHandler methodCallHandler;

  final List<Filter> filters = [
    Filter(() => 'Channels', isChannel),
    Filter(() => 'Dialogs', isDialog),
  ];

  bool _fullLoading = true;
  bool loadingChats = false;

  Set<Filter> selectedFilters = {};

  @override
  void initState() {
    super.initState();

    var methodCallHandler = MethodCallHandler();

    JavaService.instance.setMethodCallHandler((call) async {
      await methodCallHandler.handle(call);
      setState(() {});
      chatKey.currentState?.update();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _fullLoading = true);
      try {
        await start(context, methodCallHandler, () {
          if (mounted) setState(() => _fullLoading = false);
        });
      } finally {
        if (mounted) setState(() => _fullLoading = false);
      }
    });
  }

  Future<void> _updateHome({required bool animation}) async {
    if (animation && mounted) setState(() => loadingChats = true);
    try {
      await TauChat.loadAll(
        callback: () {
          if (mounted) setState(() {});
        },
        onError: (client, e) {
          if (mounted) {
            String error = "Something went wrong";
            if (e is ExpiredTokenException) {
              error = "Token for \"${client.name}\" expired";
            }
            snackBarError(context, error);
          }
        },
      ).timeout(Duration(seconds: 5));
    } finally {
      if (animation && mounted) setState(() => loadingChats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var isLight = Theme.of(context).brightness == Brightness.light;
    var color = Colors.deepOrange[isLight ? 700 : 300];

    var names = JavaService.instance.clients.values
        .where((c) => c.user != null)
        .map((c) => c.user!.nickname)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(child: AnimatedGreeting(names: names)),
                  if (loadingChats)
                    CircularProgressIndicator(
                      color: color,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TauButton.icon(
                        Icons.more_vert,
                        color: color,
                        onPressed: () => showMenuAtHome(context, () {
                          _updateHome(animation: true);
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  const duration = Duration(seconds: 5);
                  await JavaService.instance.loadClients().timeout(duration);
                  await _updateHome(animation: false);
                },
                child: _buildChatList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => _fullLoading = !_fullLoading);
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildChatList() {
    if (_fullLoading) {
      return Center(child: CircularProgressIndicator());
    }

    var clients = JavaService.instance.clients.values;

    // Collect all disconnected (but not hidden) hubs
    var disconnectedHubs =
        clients.where((c) => !c.connected && !c.hide).toList();

    // Collect all connected but unauthorized hubs
    var unauthorizedHubs = clients
        .where((c) => c.connected && (c.user == null || !c.user!.authorized))
        .toList();

    // Show "No hubs"
    // if there are no connected hubs
    if (clients.where((c) => c.connected).isEmpty) {
      return HubsEmpty(connectUpdate: () => _updateHome(animation: true));
    }

    var noChats = clients.expand((client) => client.chats.values).isEmpty;

    if (noChats) {
      // If the user is not logged in — suggest login
      if (unauthorizedHubs.isNotEmpty) {
        var client = unauthorizedHubs.first;
        if (client.user == null || !client.user!.authorized) {
          return NotLoggedIn(client, onLogin: (result) async {
            if (result is String && result.contains("success")) {
              await _updateHome(animation: true);
            }
          });
        }
      }

      // If user is logged in but there are no chats — suggest to create one
      return NoChats(updateHome: () => _updateHome(animation: false));
    }

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
      return b.messages.last.dateTime.compareTo(a.messages.last.dateTime);
    });

    List<Widget> list = [];

    for (Client client in disconnectedHubs) {
      list.add(WarningDisconnectMessage(
        client: client,
        updateHome: () {
          _updateHome(animation: true);
        },
      ));
    }

    for (Client client in unauthorizedHubs) {
      list.add(WarningUnauthorizedMessage(
        name: client.name,
        onLoginTap: () async {
          var result = await moveTo(context, LoginScreen(client: client));
          if (result is String && result.contains("success")) {
            await _updateHome(animation: true);
          }
        },
      ));
    }

    Iterable<Filter> clientFilter =
        clients.length != 1 ? clients.map((c) => c.filter) : [];
    list.add(ChatsFilter(
      filters: [...filters, ...clientFilter],
      initial: selectedFilters,
      onChange: (selected) => setState(() => selectedFilters = selected),
    ));

    for (TauChat chat in chats) {
      list.add(ChatItem(
        chat: chat,
        onTap: (chat) async {
          await moveTo(context, ChatScreen(chat, key: chatKey));
          await _updateHome(animation: true);
        },
      ));
    }

    // Build the list of widgets for the UI
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => list[i],
    );
  }
}
