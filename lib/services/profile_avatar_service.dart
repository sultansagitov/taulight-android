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
        File('${dir.path}/avatar_${uuid}_${client.user!.nickname}');
    final noAvatarFile =
        File('${dir.path}/no_avatar_${uuid}_${client.user!.nickname}');

    try {
      final map = await PlatformAvatarService.ins.getAvatar(client);
      final base64Str = map["imageBase64"];

      if (base64Str == null) {
        await noAvatarFile.writeAsString('no avatar');
        return null;
      }

      final bytes = base64Decode(base64Str);
      await avatarFile.writeAsBytes(bytes, flush: true);
      return MemoryImage(bytes);
    } catch (e) {
      return null;
    }
  }
}
