import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/platform_avatar_service.dart';

class ProfileAvatarService {
  static final ProfileAvatarService _instance =
      ProfileAvatarService._internal();
  static ProfileAvatarService get ins => _instance;
  ProfileAvatarService._internal();

  final _storage = const FlutterSecureStorage();

  Future<MemoryImage?> getAvatar(Client client) async {
    final uuid = client.uuid;

    final noAvatar = await _storage.read(key: 'no_avatar_$uuid');
    if (noAvatar != null) return null;

    final avatarBase64 = await _storage.read(key: 'avatar_$uuid');
    if (avatarBase64 != null) {
      try {
        final bytes = base64Decode(avatarBase64);
        return MemoryImage(bytes);
      } catch (e) {
        print('Failed to decode avatar: $e');
      }
    }

    try {
      final map = await PlatformAvatarService.ins.getAvatar(client);

      if (map == null) {
        await _storage.write(key: 'no_avatar_$uuid', value: 'true');
        return null;
      }

      final base64Str = map["avatarBase64"]!;
      await _storage.write(key: 'avatar_$uuid', value: base64Str);
      return MemoryImage(base64Decode(base64Str));
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      return null;
    }
  }

  Future<void> setAvatar(Client client, String path) async {
    await PlatformAvatarService.ins.setAvatar(client, path);

    final uuid = client.uuid;
    await _storage.delete(key: 'avatar_$uuid');
    await _storage.delete(key: 'no_avatar_$uuid');
  }
}
