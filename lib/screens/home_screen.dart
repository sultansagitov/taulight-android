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
    Filter('Channels', isChannel),
    Filter('Dialogs', isDialog),
  ];

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

    start(
      methodCallHandler: methodCallHandler,
      context: context,
      update: () => setState(() {}),
    );
  }

  void _updateHome() {
    (() async {
      if (mounted) setState(() => loadingChats = true);
      try {
        await TauChat.loadAll(callback: () {
          if (mounted) setState(() {});
        }, onError: (client, e) {
          if (mounted) {
            String error = "Something went wrong";
            if (e is ExpiredTokenException) {
              error = "Token for \"${client.name}\" expired";
            }
            snackBarError(context, error);
          }
        }).timeout(Duration(seconds: 5));
      } finally {
        if (mounted) setState(() => loadingChats = false);
      }
    })();
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
                        onPressed: () => showMenuAtHome(context, _updateHome),
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
                  _updateHome();
                },
                child: _buildChatList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildChatList() {
    // Show "No hubs"
    // if there are no connected hubs and no chats from disconnected hubs
    var empty =
        JavaService.instance.clients.values.where((c) => c.connected).isEmpty;

    if (empty) {
      return HubsEmpty(updateHome: _updateHome);
    }

    var noChats = JavaService.instance.clients.values
        .expand((client) => client.chats.values)
        .isEmpty;

    if (noChats) {
      var client = JavaService.instance.clients.values.first;

      // If the user is not logged in — suggest login
      if (client.user == null || !client.user!.authorized) {
        return NotLoggedIn(client, _updateHome);
      }

      // If user is logged in but there are no chats — suggest to create one
      return NoChats(_updateHome);
    }

    // Collect all chats from clients that have a valid user
    List<TauChat> chats = JavaService.instance.clients.values
        .expand((client) => client.chats.values)
        .where((chat) {
      if (selectedFilters.isEmpty) {
        return true;
      }

      for (Filter filter in selectedFilters) {
        if (filter.condition(chat)) {
          return true;
        }
      }

      return false;
    }).toList();

    // Sort chats:
    // - chats with messages come first
    // - newest messages go to the top
    chats.sort((a, b) {
      if (a.messages.isEmpty) return 1;
      if (b.messages.isEmpty) return -1;
      return b.messages.last.dateTime.compareTo(a.messages.last.dateTime);
    });

    // Collect all disconnected (but not hidden) hubs
    var disconnectedHubs = JavaService.instance.clients.values
        .where((c) => !c.connected && !c.hide)
        .toList();

    // Collect all connected but unauthorized hubs
    var unauthorizedHubs = JavaService.instance.clients.values
        .where((c) => c.connected && (c.user == null || !c.user!.authorized))
        .toList();

    List<Widget> list = [];

    for (Client client in disconnectedHubs) {
      list.add(WarningDisconnectMessage(
        client: client,
        updateHome: _updateHome,
      ));
    }

    for (Client client in unauthorizedHubs) {
      list.add(WarningUnauthorizedMessage(
        name: client.name,
        onLoginTap: () {
          var screen = LoginScreen(client: client, updateHome: _updateHome);
          moveTo(context, screen);
        },
      ));
    }

    list.add(ChatsFilter(
      filters: filters,
      initial: selectedFilters,
      onChange: (selected) => setState(() => selectedFilters = selected),
    ));

    for (TauChat chat in chats) {
      list.add(ChatItem(
        chat: chat,
        onTap: (chat) {
          var screen = ChatScreen(
            key: chatKey,
            chat: chat,
            updateHome: _updateHome,
          );
          moveTo(context, screen);
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
