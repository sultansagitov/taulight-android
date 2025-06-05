import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/platform_avatar_service.dart';

class AvatarService {
  static final AvatarService _instance = AvatarService._internal();
  static AvatarService get ins => _instance;
  AvatarService._internal();

  Future<MemoryImage?> loadOrFetchGroupAvatar(TauChat chat) async {
    return _loadOrFetchAvatar(chat, PlatformAvatarService.ins.getGroupAvatar);
  }

  Future<MemoryImage?> loadOrFetchDialogAvatar(TauChat chat) async {
    return _loadOrFetchAvatar(chat, PlatformAvatarService.ins.getDialogAvatar);
  }

  Future<MemoryImage?> _loadOrFetchAvatar(
    TauChat chat,
    Future<Map<String, String>?> Function(TauChat) fetchAvatar,
  ) async {
    final dir = await getApplicationDocumentsDirectory();

    final client = chat.client;
    final id = chat.record.id;

    final avatarFile = File('${dir.path}/avatar_${client.uuid}_$id');

    if (!await hasAvatar(chat)) {
      return null;
    }

    if (await avatarFile.exists()) {
      final bytes = await avatarFile.readAsBytes();
      return MemoryImage(bytes);
    }

    try {
      final map = await fetchAvatar(chat);

      if (map == null) {
        await setNoAvatar(client, id);
        return null;
      }

      final base64Str = map["avatarBase64"]!;
      final bytes = base64Decode(base64Str);
      print("Saving avatar for $client:$id in $avatarFile");
      await avatarFile.writeAsBytes(bytes, flush: true);
      return MemoryImage(bytes);
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      return null;
    }
  }

  Future<bool> hasAvatar(TauChat chat) async {
    final dir = await getApplicationDocumentsDirectory();

    final uuid = chat.client.uuid;
    final id = chat.record.id;

    return !await File('${dir.path}/no_avatar_${uuid}_$id').exists();
  }

  Future<void> setNoAvatar(Client client, String id) async {
    final dir = await getApplicationDocumentsDirectory();

    final uuid = client.uuid;

    final avatarFile = File('${dir.path}/avatar_${uuid}_$id');
    final noAvatarFile = File('${dir.path}/no_avatar_${uuid}_$id');

    if (await avatarFile.exists()) {
      await avatarFile.delete();
    }

    await noAvatarFile.writeAsString('no avatar');
  }

  Future<void> removeNoAvatar(Client client, String id) async {
    final dir = await getApplicationDocumentsDirectory();

    final noAvatarFile = File('${dir.path}/no_avatar_${client.uuid}_$id');

    if (await noAvatarFile.exists()) {
      await noAvatarFile.delete();
    }
  }

  Future<void> setGroupAvatar(TauChat chat, String path) async {
    await PlatformAvatarService.ins.setGroupAvatar(chat, path);
    final bytes = await File(path).readAsBytes();
    await _updateAvatar(chat.client, chat.record.id, bytes);
  }

  Future<void> _updateAvatar(
    Client client,
    String filename,
    Uint8List newImageBytes,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final uuid = client.uuid;
    final avatarFile = File('${dir.path}/avatar_${uuid}_$filename');
    final noAvatarFile = File('${dir.path}/no_avatar_${uuid}_$filename');

    if (await noAvatarFile.exists()) {
      await noAvatarFile.delete();
    }

    await avatarFile.writeAsBytes(newImageBytes, flush: true);
  }
}
