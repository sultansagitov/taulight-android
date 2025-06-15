import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/platform_service.dart';
import 'package:taulight/widget_utils.dart';

class FileService {
  static final _instance = FileService._internal();
  static FileService get ins => _instance;
  FileService._internal();

  Future<String?> downloadAndSaveFile(Client client, NamedFileDTO file) async {
    var fileData = await PlatformService.ins.downloadFile(client, file.id);

    Directory dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();

    final filePath = '${dir.path}/${file.filename}';

    final fileObj = File(filePath);
    await fileObj.writeAsBytes(fileData);

    return filePath;
  }

  Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      int sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

      if (sdkInt >= 33) {
        final photosStatus = await Permission.photos.request();
        final videosStatus = await Permission.videos.request();
        final audioStatus = await Permission.audio.request();

        if (!photosStatus.isGranted &&
            !videosStatus.isGranted &&
            !audioStatus.isGranted) {
          snackBarError(context, 'Media permissions denied');
          return false;
        }
      } else {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          snackBarError(context, 'Storage permission denied');
          return false;
        }
      }
    } else if (Platform.isIOS) {
      final photosStatus = await Permission.photos.request();
      if (!photosStatus.isGranted) {
        snackBarError(context, 'Photos permission denied');
        return false;
      }
    }

    return true;
  }
}
