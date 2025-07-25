import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/avatar.dart';
import 'package:taulight/services/platform/avatar.dart';

class ChatAvatarService {
  static final ChatAvatarService _instance = ChatAvatarService._internal();
  static ChatAvatarService get ins => _instance;
  ChatAvatarService._internal();

  Future<MemoryImage?> loadOrFetchGroupAvatar(TauChat chat) async {
    String? avatarID = chat.avatarID;
    if (avatarID == null) return null;

    var dto = await AvatarService.ins.loadOrFetchAvatar(avatarID, () async {
      if (!chat.client.connected) return {};
      return await PlatformAvatarService.ins.getGroupAvatar(chat);
    });
    return dto?.image;
  }

  Future<MemoryImage?> loadOrFetchDialogAvatar(TauChat chat) async {
    String? avatarID = chat.avatarID;
    if (avatarID == null) return null;

    var dto = await AvatarService.ins.loadOrFetchAvatar(avatarID, () async {
      if (!chat.client.connected) return {};
      return await PlatformAvatarService.ins.getDialogAvatar(chat);
    });
    return dto?.image;
  }

  Future<void> setGroupAvatar(TauChat chat, String path) async {
    var avatarID = await PlatformAvatarService.ins.setGroupAvatar(chat, path);
    final bytes = await File(path).readAsBytes();
    await AvatarService.ins.updateAvatar(avatarID, bytes);
  }
}
