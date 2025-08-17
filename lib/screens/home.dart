import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/config.dart';
import 'package:taulight/enums/main_menu.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/screens/login.dart';
import 'package:taulight/screens/main_menu.dart';
import 'package:taulight/services/client.dart';
import 'package:taulight/services/platform/client.dart';
import 'package:taulight/start_method.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/method_call_handler.dart';
import 'package:taulight/screens/chat.dart';
import 'package:taulight/services/platform/platform_service.dart';
import 'package:taulight/widgets/animated_greetings.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/widgets/chat_list.dart';
import 'package:taulight/widgets/flat_rect_button.dart';
import 'package:taulight/widgets/no_chats.dart';
import 'package:taulight/widgets/not_logged_in.dart';

import 'package:taulight/widgets/hubs_empty.dart';
import 'package:taulight/widgets/tau_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

    final methodCallHandler = MethodCallHandler();

    PlatformService.ins.setMethodCallHandler((call) async {
      try {
        final result = await methodCallHandler.handle(call);
        setState(() {});
        chatKey.currentState?.update();
        return result;
      } catch (e, stackTrace) {
        print(e);
        print(stackTrace);
        rethrow;
      }
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

  Future<void> _newChatDialog(BuildContext context, VoidCallback update) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Start new chat",
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              FlatRectButton(
                label: "Start Dialog",
                icon: Icons.chat_bubble_outline,
                onPressed: () {
                  Navigator.pop(context);
                  MainMenu.newDialogAction(context, update);
                },
              ),
              const SizedBox(height: 12),
              FlatRectButton(
                label: "Create Group",
                icon: Icons.group_outlined,
                onPressed: () {
                  Navigator.pop(context);
                  MainMenu.newGroupAction(context, update);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final color = Config.primarySwatch[isLight ? 700 : 300];

    final names = ClientService.ins.clientsList
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
                  TauButton.icon(
                    Icons.menu,
                    color: color,
                    onPressed: () async {
                      final screen = MainMenuScreen();
                      await moveTo(context, screen, fromLeft: true);
                      await _updateHome(animation: false);
                    },
                  ),
                  if (loadingChats)
                    CircularProgressIndicator(
                      color: color,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  Expanded(child: AnimatedGreeting(names: names)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  const duration = Duration(seconds: 5);
                  final clients = ClientService.ins.clientsList;
                  for (final c in clients.where((c) => !c.connected)) {
                    await c.reload().timeout(duration);
                  }
                  await PlatformClientService.ins
                      .loadClients()
                      .timeout(duration);
                  for (final c in clients.where((c) => c.realName == null)) {
                    await c.resetName().timeout(duration);
                  }
                  for (final client in ClientService.ins.clientsList) {
                    for (final chat in client.chats.values) {
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
        onPressed: () => _newChatDialog(context, () {
          _updateHome(animation: false);
        }),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildChatList() {
    if (_fullLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          ...ClientService.ins.clientsList.map((client) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    client.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    client.status.str,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: client.status.color,
                    ),
                  ),
                ],
              ),
            );
          })
        ],
      );
    }

    final clients = ClientService.ins.clientsList;

    // Collect all connected but unauthorized hubs
    final unauthorizedHubs = clients
        .where((c) => c.connected && (c.user == null || !c.user!.authorized))
        .toList();

    // Show "No hubs"
    // if there are no connected hubs (show grey chats if disconnect)
    if (clients.where((c) => c.connected || c.chats.isNotEmpty).isEmpty) {
      return HubsEmpty(connectUpdate: () => _updateHome(animation: true));
    }

    final noChats = clients.expand((client) => client.chats.values).isEmpty;

    if (noChats) {
      // If the user is not logged in — suggest login
      if (unauthorizedHubs.isNotEmpty) {
        final client = unauthorizedHubs.first;
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
        final screen = ChatScreen(chat, key: chatKey, updateHome: () {
          _updateHome(animation: true);
        });
        await moveTo(context, screen);
        await _updateHome(animation: false);
      },
      onLoginTap: (Client client) async {
        final result = await moveTo(context, LoginScreen(client: client));
        if (result is String && result.contains("success")) {
          await _updateHome(animation: true);
        }
      },
    );
  }
}
