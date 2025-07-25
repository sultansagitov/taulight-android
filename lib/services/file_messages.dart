import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/platform/messages.dart';
import 'package:taulight/widget_utils.dart';

class FileMessageService {
  static final FileMessageService _instance = FileMessageService._internal();
  static FileMessageService get ins => _instance;
  FileMessageService._internal();

  final _storage = const FlutterSecureStorage();

  // Save local file path linked to file ID
  Future<void> registerLocalFile(String fileId, String path) async {
    await _storage.write(key: 'file_$fileId', value: path);
  }

  // Get saved local file path for file ID
  Future<String?> getLocalPathForFile(String fileId) async {
    return await _storage.read(key: 'file_$fileId');
  }

  // Upload file and register it locally
  Future<String> uploadFile(TauChat chat, String path, String filename) async {
    final id =
        await PlatformMessagesService.ins.uploadFile(chat, path, filename);
    await registerLocalFile(id, path);
    return id;
  }

  // Download bytes from server
  Future<Uint8List> downloadFile(Client client, String id) async {
    return await PlatformMessagesService.ins.downloadFile(client, id);
  }

  // Default file path in documents directory
  Future<String> getLocalFilePath(NamedFileDTO file) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${file.filename}';
  }

  // Check if file is stored locally (registered or default path)
  Future<bool> isFileDownloaded(NamedFileDTO file) async {
    if (file.id == null) return false;

    final cached = await getLocalPathForFile(file.id!);
    if (cached != null && File(cached).existsSync()) return true;

    final path = await getLocalFilePath(file);
    return File(path).existsSync();
  }

  /// 🔧 NEW: Load local file only, do NOT download
  Future<String?> getLocalFileOnly(NamedFileDTO file) async {
    if (file.id == null) return null;

    final cached = await getLocalPathForFile(file.id!);
    if (cached != null && File(cached).existsSync()) return cached;

    final defaultPath = await getLocalFilePath(file);
    if (File(defaultPath).existsSync()) return defaultPath;

    return null; // Not available locally
  }

  /// ✅ Download only if not available locally
  Future<String?> downloadAndSaveFile(Client client, NamedFileDTO file) async {
    if (file.id == null) return null;

    // Try registered path first
    final cached = await getLocalPathForFile(file.id!);
    if (cached != null && File(cached).existsSync()) return cached;

    // Try default path
    final defaultPath = await getLocalFilePath(file);
    if (File(defaultPath).existsSync()) {
      await registerLocalFile(file.id!, defaultPath);
      return defaultPath;
    }

    // Otherwise, download
    final bytes = await downloadFile(client, file.id!);
    await File(defaultPath).writeAsBytes(bytes);
    await registerLocalFile(file.id!, defaultPath);
    return defaultPath;
  }

  /// Open file using OpenFile plugin (only if exists locally)
  Future<void> openFile(NamedFileDTO file) async {
    final localPath = await getLocalFileOnly(file);
    if (localPath != null) {
      await OpenFile.open(localPath);
    } else {
      throw Exception('File not available locally.');
    }
  }

  /// Ask for storage/media permission based on platform
  Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

      if (sdk >= 33) {
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        final audio = await Permission.audio.request();

        if (!photos.isGranted && !videos.isGranted && !audio.isGranted) {
          snackBarError(context, 'Media permissions denied');
          return false;
        }
      } else {
        final storage = await Permission.storage.request();
        if (!storage.isGranted) {
          snackBarError(context, 'Storage permission denied');
          return false;
        }
      }
    } else if (Platform.isIOS) {
      final photos = await Permission.photos.request();
      if (!photos.isGranted) {
        snackBarError(context, 'Photos permission denied');
        return false;
      }
    }

    return true;
  }
}
