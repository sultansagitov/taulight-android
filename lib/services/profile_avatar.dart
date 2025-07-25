import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/avatar.dart';
import 'package:taulight/services/platform/avatar.dart';

class ProfileAvatarService {
  static final _instance = ProfileAvatarService._internal();
  static ProfileAvatarService get ins => _instance;
  ProfileAvatarService._internal();

  final _storage = const FlutterSecureStorage();

  Future<MemoryImage?> getMy(Client client) async {
    final address = client.address;
    final nickname = client.user!.nickname;

    final avatarID =
        await _storage.read(key: 'member_avatar_$address:$nickname');
    if (avatarID == 'no_avatar') return null;

    ImageDTO? dto;
    try {
      dto = await AvatarService.ins.loadOrFetchAvatar(avatarID, () async {
        if (!client.connected) return {};
        return await PlatformAvatarService.ins.getMy(client);
      });
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      return null;
    }

    if (dto != null) {
      await _storage.write(
          key: 'member_avatar_$address:$nickname', value: dto.id!);
    }

    return dto?.image;
  }

  Future<MemoryImage?> getOf(Client client, String nickname) async {
    final address = client.address;

    final avatarID =
        await _storage.read(key: 'member_avatar_$address:$nickname');
    if (avatarID == 'no_avatar') return null;

    var dto = await AvatarService.ins.loadOrFetchAvatar(avatarID, () async {
      if (!client.connected) return {};
      return await PlatformAvatarService.ins.getOf(client, nickname);
    });

    if (dto != null) {
      await _storage.write(
        key: 'member_avatar_$address:$nickname',
        value: dto.id!,
      );
    }

    return dto?.image;
  }

  Future<void> setMy(Client client, String path) async {
    final avatarID = await PlatformAvatarService.ins.setMy(client, path);
    final address = client.address;
    final nickname = client.user!.nickname;

    final file = File(path);
    if (!await file.exists()) {
      print('Avatar file does not exist at $path');
      return;
    }

    final bytes = await file.readAsBytes();

    final oldAvatarID =
        await _storage.read(key: 'member_avatar_$address:$nickname');
    if (oldAvatarID != null && oldAvatarID != 'no_avatar') {
      await AvatarService.ins.remove(oldAvatarID);
    }

    await _storage.write(
        key: 'member_avatar_$address:$nickname', value: avatarID);
    await AvatarService.ins.updateAvatar(avatarID, bytes);
  }
}
