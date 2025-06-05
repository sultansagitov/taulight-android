import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/platform_avatar_service.dart';

class ProfileAvatarService {
  static final ProfileAvatarService _instance =
      ProfileAvatarService._internal();
  static ProfileAvatarService get ins => _instance;
  ProfileAvatarService._internal();

  Future<MemoryImage?> getAvatar(Client client) async {
    final dir = await getApplicationDocumentsDirectory();

    final uuid = client.uuid;
    final avatarFile =
        File('${dir.path}/avatar_$uuid');
    final noAvatarFile =
        File('${dir.path}/no_avatar_$uuid');

    if (await noAvatarFile.exists()) {
      return null;
    }

    if (await avatarFile.exists()) {
      var bytes = await avatarFile.readAsBytes();
      return MemoryImage(bytes);
    }

    try {
      final map = await PlatformAvatarService.ins.getAvatar(client);

      if (map == null) {
        await noAvatarFile.writeAsString('no avatar');
        return null;
      }

      print(map);

      final base64Str = map["avatarBase64"]!;
      final bytes = base64Decode(base64Str);
      await avatarFile.writeAsBytes(bytes, flush: true);
      return MemoryImage(bytes);
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      return null;
    }
  }

  Future<void> setAvatar(Client client, String path) async {
    await PlatformAvatarService.ins.setAvatar(client, path);
  }
}
