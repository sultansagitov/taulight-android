import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taulight/config.dart';
import 'package:taulight/providers/message_time.dart';
import 'package:taulight/providers/theme.dart';
import 'package:taulight/screens/pin.dart';

void main() {
  runApp(
    const ProviderScope(child: TaulightApp()),
  );
}

class TaulightApp extends ConsumerStatefulWidget {
  const TaulightApp({super.key});

  @override
  ConsumerState<TaulightApp> createState() => _TaulightAppState();
}

class _TaulightAppState extends ConsumerState<TaulightApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(themeNotifierProvider.notifier).load();
      ref.read(messageTimeNotifierProvider.notifier).load();
    });

    // _sub = uriLinkStream.listen((Uri? uri) {
    //   if (uri != null) print("Received deep link: ${uri.toString()}");
    // }, onError: (err) => print("Error receiving deep link: $err"));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider).themeMode;

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
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 12),
          bodyLarge: TextStyle(fontSize: 14),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      themeMode: themeMode,
      home: const PinScreen(),
    );
  }
}
