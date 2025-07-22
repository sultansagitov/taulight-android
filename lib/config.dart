import 'package:flutter/material.dart';
import 'package:taulight/services/storage_service.dart';

class Config {
  static Color seedColor = Colors.deepOrangeAccent;
  static MaterialColor primarySwatch = Colors.deepOrange;

  static var recommended = [
    ServerRecord(
      name: "Local Hub",
      link: "sandnode://hub@192.168.42.39?encryption=ECIES"
          "&key=MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEI81q"
          "ClQdolhofu7FLwlvZYnvgNJQ3EajfSJsKIb0bjJOuOlAB"
          "TCwDBA7pOj3pxMxuAKA5hnpX8T8hoMPdXG%2FyA%3D%3D",
    ),
    ServerRecord(
      name: "Local Hub",
      link: "sandnode://hub@192.168.1.100?encryption=ECIES"
          "&key=MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEI81q"
          "ClQdolhofu7FLwlvZYnvgNJQ3EajfSJsKIb0bjJOuOlAB"
          "TCwDBA7pOj3pxMxuAKA5hnpX8T8hoMPdXG%2FyA%3D%3D",
    ),
    ServerRecord(
      name: "Hub on Serveo",
      link: "sandnode://hub@serveo.net?encryption=ECIES"
          "&key=MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEx"
          "4Wm6M9gPirLIwFTYWCyX30kou80KOOSoUVdD6T0MP0"
          "zztAK%2BzwhVOEljQz3N%2FwL2OyG1%2FQj%2FrlUU"
          "G3R0MK%2BBg%3D%3D",
    ),
  ];

  static Map<String, String> reactions = {
    "taulight:fire": "🔥",
    "taulight:wow": "🤩",
    "taulight:sad": "😔",
    "taulight:angry": "😡",
    "taulight:like": "👍",
    "taulight:laugh": "🤣",
  };
}
