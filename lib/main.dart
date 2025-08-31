import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taulight/config.dart';
import 'package:taulight/providers/message_time.dart';
import 'package:taulight/providers/theme.dart';
import 'package:taulight/screens/pin.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MessageTimeProvider()),
      ],
      child: const TaulightApp(),
    ),
  );
}

class TaulightApp extends StatefulWidget {
  const TaulightApp({super.key});

  @override
  State<TaulightApp> createState() => _TaulightAppState();
}

class _TaulightAppState extends State<TaulightApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    // _sub = uriLinkStream.listen((Uri? uri) {
    //   if (uri != null) {
    //     print("Received deep link: ${uri.toString()}");
    //     // TODO
    //   }
    // }, onError: (err) {
    //   print("Error receiving deep link: $err");
    // });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Taulight Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Config.seedColor),
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 12),
          bodyLarge: TextStyle(fontSize: 14),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Config.seedColor,
          brightness: Brightness.dark,
        ),
        primarySwatch: Config.primarySwatch,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 12),
          bodyLarge: TextStyle(fontSize: 14),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: const PinScreen(),
    );
  }
}
