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
import 'package:taulight/services/platform_messages_service.dart';
import 'package:taulight/widget_utils.dart';

class FileMessageService {
  static final FileMessageService _instance = FileMessageService._internal();
  static FileMessageService get ins => _instance;
  FileMessageService._internal();

  final _storage = const FlutterSecureStorage();

  Future<void> registerLocalFile(String fileId, String path) async {
    await _storage.write(key: 'file_$fileId', value: path);
  }

  Future<String?> getLocalPathForFile(String fileId) async {
    return await _storage.read(key: 'file_$fileId');
  }

  Future<String> uploadFile(TauChat chat, String path, String filename) async {
    final id = await PlatformMessagesService.ins.uploadFile(chat, path, filename);
    await registerLocalFile(id, path);
    return id;
  }

  Future<Uint8List> downloadFile(Client client, String id) async {
    return await PlatformMessagesService.ins.downloadFile(client, id);
  }

  Future<String> getLocalFilePath(NamedFileDTO file) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${file.filename}';
  }

  Future<bool> isFileDownloaded(NamedFileDTO file) async {
    final cached = await getLocalPathForFile(file.id!);
    if (cached != null && File(cached).existsSync()) return true;

    final path = await getLocalFilePath(file);
    return File(path).existsSync();
  }

  Future<String?> downloadAndSaveFile(Client client, NamedFileDTO file) async {
    final cached = await getLocalPathForFile(file.id!);
    if (cached != null && File(cached).existsSync()) return cached;

    final bytes = await downloadFile(client, file.id!);
    final path = await getLocalFilePath(file);

    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<void> openFile(NamedFileDTO file) async {
    final cached = await getLocalPathForFile(file.id!);
    final path = cached ?? await getLocalFilePath(file);

    final f = File(path);
    if (await f.exists()) {
      await OpenFile.open(path);
    } else {
      throw Exception('File not found: $path');
    }
  }

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