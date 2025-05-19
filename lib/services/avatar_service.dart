import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/platform_service.dart';

class AvatarService {
  static final AvatarService _instance = AvatarService._internal();
  static AvatarService get ins => _instance;
  AvatarService._internal();

  Future<MemoryImage?> loadOrFetchChannelAvatar(TauChat chat) async {
    return _loadOrFetchAvatar(chat, PlatformService.ins.getChannelAvatar);
  }

  Future<MemoryImage?> loadOrFetchDialogAvatar(TauChat chat) async {
    return _loadOrFetchAvatar(chat, PlatformService.ins.getDialogAvatar);
  }

  Future<MemoryImage?> _loadOrFetchAvatar(
    TauChat chat,
    Future<Map<String, dynamic>> Function(TauChat) fetchAvatar,
  ) async {
    final dir = await getApplicationDocumentsDirectory();

    final client = chat.client;

    final uuid = client.uuid;
    final avatarFile = File('${dir.path}/avatar_${uuid}_${chat.record.id}');
    final noAvatarFile =
        File('${dir.path}/no_avatar_${uuid}_${chat.record.id}');

    if (await noAvatarFile.exists()) {
      return null;
    }

    if (await avatarFile.exists()) {
      final bytes = await avatarFile.readAsBytes();
      return MemoryImage(bytes);
    }

    try {
      final map = await fetchAvatar(chat);
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

  Future<void> setChannelAvatar(TauChat chat, String path) async {
    await PlatformService.ins.setChannelAvatar(chat, path);
    final bytes = await File(path).readAsBytes();
    await updateAvatar(chat.client, chat.record.id, bytes);
  }

  Future<void> updateAvatar(
    Client client,
    String filename,
    Uint8List newImageBytes,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    var uuid = client.uuid;
    var avatarFile = File('${dir.path}/avatar_${uuid}_$filename');
    var noAvatarFile = File('${dir.path}/no_avatar_${uuid}_$filename');

    if (await noAvatarFile.exists()) {
      await noAvatarFile.delete();
    }

    await avatarFile.writeAsBytes(newImageBytes, flush: true);
  }
}
