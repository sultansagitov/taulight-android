import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ImageDTO {
  final String? id;
  final MemoryImage image;

  ImageDTO(this.id, this.image);
}

class AvatarService {
  static final AvatarService _instance = AvatarService._internal();
  static AvatarService get ins => _instance;
  AvatarService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final int _cacheSize = 20;

  final LinkedHashMap<String, ImageDTO> _memoryCache = LinkedHashMap();

  String _avatarKey(String avatarID) => 'avatar_$avatarID';

  Future<ImageDTO?> loadOrFetchAvatar(
      String? avatarID,
      Future<Map<String, String>?> Function() fetchAvatar,
      ) async {
    if (avatarID != null) {
      if (_memoryCache.containsKey(avatarID)) {
        return _memoryCache[avatarID];
      }

      final avatarData = await _secureStorage.read(key: _avatarKey(avatarID));
      if (avatarData != null) {
        final bytes = base64Decode(avatarData);
        final dto = ImageDTO(avatarID, MemoryImage(bytes));
        _addToCache(avatarID, dto);
        return dto;
      }
    }

    try {
      final map = await fetchAvatar();
      if (map == null || map.isEmpty) return null;

      final id = map["id"]!;
      final base64Str = map["avatarBase64"]!;
      await _secureStorage.write(key: _avatarKey(id), value: base64Str);

      final bytes = base64Decode(base64Str);
      final dto = ImageDTO(id, MemoryImage(bytes));
      _addToCache(id, dto);
      return dto;
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      return null;
    }
  }

  Future<void> remove(String oldAvatarID) async {
    await _secureStorage.delete(key: _avatarKey(oldAvatarID));
    _memoryCache.remove(oldAvatarID);
  }

  Future<bool> hasAvatarInStorage(String avatarID) async {
    if (_memoryCache.containsKey(avatarID)) return true;
    final avatarData = await _secureStorage.read(key: _avatarKey(avatarID));
    return avatarData != null;
  }

  Future<void> updateAvatar(String avatarID, Uint8List newImageBytes) async {
    final base64Str = base64Encode(newImageBytes);
    await _secureStorage.write(key: _avatarKey(avatarID), value: base64Str);
    final dto = ImageDTO(avatarID, MemoryImage(newImageBytes));
    _addToCache(avatarID, dto);
  }

  void _addToCache(String key, ImageDTO dto) {
    _memoryCache.remove(key);
    _memoryCache[key] = dto;

    if (_memoryCache.length > _cacheSize) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
  }
}