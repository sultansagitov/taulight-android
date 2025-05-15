import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/java_service.dart';

class AvatarService {
  static final AvatarService _instance = AvatarService._internal();
  static AvatarService get instance => _instance;
  AvatarService._internal();

  Future<MemoryImage?> loadOrFetchChannelAvatar(TauChat chat) async {
    return _loadOrFetchAvatar(chat, JavaService.instance.getChannelAvatar);
  }

  Future<MemoryImage?> loadOrFetchDialogAvatar(TauChat chat) async {
    return _loadOrFetchAvatar(chat, JavaService.instance.getDialogAvatar);
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

  Future<void> updateAvatar(TauChat chat, Uint8List newImageBytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final client = chat.client;
    var uuid = client.uuid;
    var avatarFile = File('${dir.path}/avatar_${uuid}_${chat.record.id}');
    var noAvatarFile = File('${dir.path}/no_avatar_${uuid}_${chat.record.id}');

    if (await noAvatarFile.exists()) {
      await noAvatarFile.delete();
    }

    await avatarFile.writeAsBytes(newImageBytes, flush: true);
  }

  Future<void> setChannelAvatar(TauChat chat, String path) async {
    final bytes = await File(path).readAsBytes();
    await JavaService.instance.setChannelAvatar(chat, path);
    await updateAvatar(chat, bytes);
  }
}
