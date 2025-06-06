import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/platform_avatar_service.dart';

class AvatarService {
  static final AvatarService _instance = AvatarService._internal();
  static AvatarService get ins => _instance;
  AvatarService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<MemoryImage?> loadOrFetchGroupAvatar(TauChat chat) async {
    return _loadOrFetchAvatar(chat, PlatformAvatarService.ins.getGroupAvatar);
  }

  Future<MemoryImage?> loadOrFetchDialogAvatar(TauChat chat) async {
    return _loadOrFetchAvatar(chat, PlatformAvatarService.ins.getDialogAvatar);
  }

  String _avatarKey(String avatarID) => 'avatar_$avatarID';

  Future<MemoryImage?> _loadOrFetchAvatar(
    TauChat chat,
    Future<Map<String, String>?> Function(TauChat) fetchAvatar,
  ) async {
    final avatarID = chat.avatarID;
    if (avatarID == null) return null;

    final avatarData = await _secureStorage.read(key: _avatarKey(avatarID));
    if (avatarData != null) {
      final bytes = base64Decode(avatarData);
      return MemoryImage(bytes);
    }

    try {
      final map = await fetchAvatar(chat);
      if (map == null) return null;

      final base64Str = map["avatarBase64"]!;
      await _secureStorage.write(key: _avatarKey(avatarID), value: base64Str);

      final bytes = base64Decode(base64Str);
      return MemoryImage(bytes);
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      return null;
    }
  }

  Future<bool> hasAvatarInStorage(TauChat chat) async {
    final avatarID = chat.avatarID;
    if (avatarID == null) return false;

    final avatarData = await _secureStorage.read(key: _avatarKey(avatarID));
    return avatarData != null;
  }

  Future<void> setGroupAvatar(TauChat chat, String path) async {
    final avatarID = chat.avatarID;
    if (avatarID == null) return;

    await PlatformAvatarService.ins.setGroupAvatar(chat, path);
    final bytes = await File(path).readAsBytes();
    await _updateAvatar(avatarID, bytes);
  }

  Future<void> _updateAvatar(String avatarID, Uint8List newImageBytes) async {
    final base64Str = base64Encode(newImageBytes);
    await _secureStorage.write(key: _avatarKey(avatarID), value: base64Str);
  }
}
