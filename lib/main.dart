import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taulight/screens/pin_screen.dart';

void main() {
  runApp(const TaulightApp());
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
    return MaterialApp(
      title: 'Taulight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrangeAccent),
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 12),
          bodyLarge: TextStyle(fontSize: 14),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrangeAccent,
          brightness: Brightness.dark,
        ),
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF121212),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 12),
          bodyLarge: TextStyle(fontSize: 14),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      home: PinScreen(),
    );
  }
}
