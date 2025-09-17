import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerKeyState {
  final bool fetch;
  ServerKeyState({required this.fetch});
}

class ServerKeyNotifier extends StateNotifier<ServerKeyState> {
  ServerKeyNotifier() : super(ServerKeyState(fetch: false));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = ServerKeyState(fetch: prefs.getBool('fetch') ?? false);
  }

  Future<void> setFetch(bool option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fetch', option);
    state = ServerKeyState(fetch: option);
  }
}

final serverKeyNotifierProvider =
    StateNotifierProvider<ServerKeyNotifier, ServerKeyState>(
  (ref) => ServerKeyNotifier(),
);
