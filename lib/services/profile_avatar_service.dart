import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/avatar_service.dart';
import 'package:taulight/services/platform_avatar_service.dart';

class ProfileAvatarService {
  static final ProfileAvatarService _instance =
      ProfileAvatarService._internal();
  static ProfileAvatarService get ins => _instance;
  ProfileAvatarService._internal();

  final _storage = const FlutterSecureStorage();

  Future<MemoryImage?> getAvatar(Client client) async {
    final uuid = client.uuid;

    final avatarID = await _storage.read(key: 'client_avatar_$uuid');
    if (avatarID == 'no_avatar') return null;

    var dto = await AvatarService.ins.loadOrFetchAvatar(avatarID, () {
      return PlatformAvatarService.ins.getAvatar(client);
    });

    if (dto != null) {
      await _storage.write(key: 'client_avatar_$uuid', value: dto.id!);
    }

    return dto?.image;
  }

  Future<void> setAvatar(Client client, String path) async {
    final avatarID = await PlatformAvatarService.ins.setAvatar(client, path);
    final uuid = client.uuid;

    final file = File(path);
    if (!await file.exists()) {
      print('Avatar file does not exist at $path');
      return;
    }

    final bytes = await file.readAsBytes();

    final oldAvatarID = await _storage.read(key: 'client_avatar_$uuid');
    if (oldAvatarID != null && oldAvatarID != 'no_avatar') {
      await AvatarService.ins.remove(oldAvatarID);
    }

    await _storage.write(key: 'client_avatar_$uuid', value: avatarID);
    await AvatarService.ins.updateAvatar(avatarID, bytes);
  }
}
