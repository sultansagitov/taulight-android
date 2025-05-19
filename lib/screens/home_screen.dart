import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/menus/home.dart';
import 'package:taulight/screens/login_screen.dart';
import 'package:taulight/services/client_service.dart';
import 'package:taulight/start_method.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/method_call_handler.dart';
import 'package:taulight/screens/chat_screen.dart';
import 'package:taulight/services/platform_service.dart';
import 'package:taulight/widgets/animated_greetings.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/widgets/chat_list.dart';
import 'package:taulight/widgets/no_chats.dart';
import 'package:taulight/widgets/not_logged_in.dart';

import 'package:taulight/widgets/hubs_empty.dart';
import 'package:taulight/widgets/tau_button.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen() : super(key: GlobalKey<HomeScreenState>());

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final chatKey = GlobalKey<ChatScreenState>();
  late final MethodCallHandler methodCallHandler;

  bool _fullLoading = true;
  bool loadingChats = false;

  @override
  void initState() {
    super.initState();

    var methodCallHandler = MethodCallHandler();

    PlatformService.ins.setMethodCallHandler((call) async {
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
      if (mounted) setState(() => loadingChats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var isLight = Theme.of(context).brightness == Brightness.light;
    var color = Colors.deepOrange[isLight ? 700 : 300];

    var names = ClientService.ins.clientsList
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
                  var clients = ClientService.ins.clientsList;
                  for (var c in clients.where((c) => !c.connected)) {
                    await c.reload().timeout(duration);
                  }
                  await PlatformService.ins.loadClients().timeout(duration);
                  for (var c in clients.where((c) => c.realName == null)) {
                    await c.resetName().timeout(duration);
                  }
                  for (var client in ClientService.ins.clientsList) {
                    for (var chat in client.chats.values) {
                      await chat.loadMessages(0, 1).timeout(duration);
                    }
                  }
                  await _updateHome(animation: false).timeout(duration);
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

    var clients = ClientService.ins.clientsList;

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

    return ChatList(
      updateHome: () {
        _updateHome(animation: true);
      },
      onChatTap: (TauChat chat) async {
        await moveTo(context, ChatScreen(chat, key: chatKey));
        await _updateHome(animation: true);
      },
      onLoginTap: (Client client) async {
        var result = await moveTo(context, LoginScreen(client: client));
        if (result is String && result.contains("success")) {
          await _updateHome(animation: true);
        }
      },
    );
  }
}
