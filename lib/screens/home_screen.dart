import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/user.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/dialogs/dialog_dialog.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/screens/connection_screen.dart';
import 'package:taulight/dialogs/channel_dialog.dart';
import 'package:taulight/method_call_handler.dart';
import 'package:taulight/screens/chat_screen.dart';
import 'package:taulight/screens/hubs_screen.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/widgets/animated_greetings.dart';
import 'package:taulight/widgets/chat_item.dart';
import 'package:taulight/screens/login.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/widgets/tau_buton.dart';

import 'package:taulight/widgets/hubs_empty.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen() : super(key: GlobalKey<HomeScreenState>());

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final chatKey = GlobalKey<ChatScreenState>();
  late final MethodCallHandler methodCallHandler;

  bool loadingChats = false;

  @override
  void initState() {
    super.initState();
    JavaService.instance.setMethodCallHandler(_handleNativeMessage);
    methodCallHandler = MethodCallHandler();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => loadingChats = true);
      await JavaService.instance.loadClients();

      Map<String, ServerRecord> map = await StorageService.getClients();

      Set<String> connectedSet = JavaService.instance.clients.keys.toSet();
      Set<String> storageSet = map.keys.toSet();

      Set<String> notConnectedId = storageSet.difference(connectedSet);

      for (String uuid in notConnectedId) {
        ServerRecord sr = map[uuid]!;
        try {
          await JavaService.instance.connectWithUUID(uuid, sr.link);
        } on ConnectionException {
          if (mounted) {
            snackBar(context, "Connection error: ${sr.name}");
          }
        } finally {
          Client c = JavaService.instance.clients[uuid]!;
          UserRecord? userRecord = sr.user;
          if (userRecord != null) {
            String nickname = userRecord.nickname;
            String token = userRecord.token;
            c.user = User.unauthorized(c, nickname, token);
          }
        }
      }

      for (var client in JavaService.instance.clients.values) {
        if (!client.connected) continue;

        if (client.user == null) {
          ServerRecord? serverRecord = map[client.uuid];
          if (serverRecord != null && serverRecord.user != null) {
            try {
              var token = serverRecord.user!.token;
              var nickname = await client.authByToken(token);
              client.user = User(client, nickname, token);
            } on ExpiredTokenException {
              if (mounted) {
                snackBar(context, "Session expired. ${client.name}");
              }
              await StorageService.removeToken(client);
            } on InvalidTokenException {
              if (mounted) {
                snackBar(context, "Invalid token. ${client.name}");
              }
              await StorageService.removeToken(client);
            }
          }
        }
      }

      await TauChat.loadAll();
      setState(() => loadingChats = false);
    });
  }

  void _updateHome() {
    (() async {
      setState(() => loadingChats = true);
      try {
        await TauChat.loadAll(() => setState(() {}))
            .timeout(Duration(seconds: 5));
      } finally {
        setState(() => loadingChats = false);
      }
    })();
  }

  Future<void> _handleNativeMessage(MethodCall call) async {
    await methodCallHandler.handle(call);
    setState(() {});
    chatKey.currentState?.update();
  }

  Future<void> _showContextMenu() async {
    var value = await showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 0, 0, 0),
      items: const [
        PopupMenuItem(value: "connect", child: Text("Connect")),
        PopupMenuItem(value: "connected", child: Text("Show connected hubs")),
        PopupMenuItem(value: "new-channel", child: Text("Create channel")),
        PopupMenuItem(value: "new-dialog", child: Text("Start dialog")),
        PopupMenuItem(value: "clear-storage", child: Text("Clear storage")),
      ],
    );

    if (context.mounted && value != null) {
      switch (value) {
        case "connect":
          _createChannel(context);
          break;
        case "connected":
          moveTo(context, HubsScreen(updateHome: _updateHome));
          break;
        case "new-channel":
          channelDialog(context, _updateHome);
          break;
        case "new-dialog":
          dialogDialog(context, _updateHome);
          break;
        case "clear-storage":
          await StorageService.clear();
          break;
      }
    }
  }

  void _onChatTap(TauChat chat) {
    moveTo(context, ChatScreen(key: chatKey, chat: chat));
  }

  void _onLoginTap(Client client) {
    moveTo(context, LoginScreen(client: client, updateHome: _updateHome));
  }

  @override
  Widget build(BuildContext context) {
    var isLight = Theme.of(context).brightness == Brightness.light;
    const names = ['John Doe', 'Jane Smith', 'Alice Brown'];
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
                  Expanded(
                    child: const AnimatedGreeting(names: names),
                  ),
                  if (loadingChats)
                    CircularProgressIndicator(
                      color: Colors.deepOrange[isLight ? 700 : 300],
                      padding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          color: Colors.deepOrange[isLight ? 700 : 300],
                          onPressed: _showContextMenu,
                        ),
                      ],
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
        onPressed: () => setState(() {
          for (var client in JavaService.instance.clients.values) {
            for (var chat in client.chats.values) {
              chat.messages.clear();
            }
          }
        }),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildChatList() {
    bool empty = JavaService.instance.clients.values
        .where((c) => c.connected || c.chats.isNotEmpty)
        .isEmpty;

    if (empty) return HubsEmpty(updateHome: _updateHome);

    List<TauChat> chats = JavaService.instance.clients.values
        .where((c) => c.user != null)
        .expand((client) => client.chats.values)
        .toList();

    Map<String, int> chatIdCount = {};
    for (var chat in chats) {
      chatIdCount[chat.id] = (chatIdCount[chat.id] ?? 0) + 1;
    }

    chats.sort((a, b) {
      if (a.messages.isEmpty) return 1;
      if (b.messages.isEmpty) return -1;
      return b.messages.last.dateTime.compareTo(a.messages.last.dateTime);
    });

    var disconnectedHubs = JavaService.instance.clients.values
        .where((c) => !c.connected && !c.hide)
        .toList();

    var unauthorizedHubs = JavaService.instance.clients.values
        .where((c) => c.connected && c.user == null)
        .toList();

    int itemCount = disconnectedHubs.length +
        unauthorizedHubs.length +
        max(1, chats.length);

    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < disconnectedHubs.length) {
          var client = disconnectedHubs[index];
          return WarningMessage(client: client, updateHome: _updateHome);
        }

        int unauthorizedIndex = index - disconnectedHubs.length;
        if (unauthorizedIndex < unauthorizedHubs.length) {
          Client client = unauthorizedHubs[unauthorizedIndex];
          return Container(
            color: Colors.yellow[200],
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        client.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      const Text(
                        " not authenticated",
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _onLoginTap(client),
                  child: Text("Login", style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          );
        }

        if (chats.isEmpty) {
          return SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No chats", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  TauButton(
                    "Create channel",
                    onPressed: () => _createChannel(context),
                  ),
                ],
              ),
            ),
          );
        }

        int chatIndex = unauthorizedIndex - unauthorizedHubs.length;
        TauChat chat = chats[chatIndex];

        return ChatItem(
          chat: chat,
          onTap: _onChatTap,
          dup: chatIdCount[chat.id]! > 1,
        );
      },
    );
  }

  Future<dynamic> _createChannel(BuildContext context) {
    return moveTo(context, ConnectionScreen(updateHome: _updateHome));
  }
}

class WarningMessage extends StatefulWidget {
  final Client client;
  final VoidCallback? updateHome;

  const WarningMessage({super.key, this.updateHome, required this.client});

  @override
  State<WarningMessage> createState() => _WarningMessageState();
}

class _WarningMessageState extends State<WarningMessage> {
  bool loading = false;

  void _refresh() async {
    setState(() => loading = true);
    try {
      await widget.client.reload();
    } on ConnectionException {
      if (mounted) {
        snackBar(context, "Connection exception: ${widget.client.name}");
      }
    } finally {
      setState(() => loading = false);
      if (widget.updateHome != null) widget.updateHome!();
    }
  }

  void _visibilityOff() {
    widget.client.hide = true;
    if (widget.updateHome != null) widget.updateHome!();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red[200],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => openHubDialog(context, widget.client),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.black),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.client.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                  const Text(
                    " disconnected",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          if (!loading) ...[
            IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.refresh, color: Colors.black),
              onPressed: _refresh,
            ),
            IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.visibility_off, color: Colors.black),
              onPressed: _visibilityOff,
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(4),
              child: CircularProgressIndicator(color: Colors.black),
            ),
          ]
        ],
      ),
    );
  }
}
