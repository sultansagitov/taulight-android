import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taulight/widget_utils.dart';

class PreviewImage extends StatelessWidget {
  final Image image;

  const PreviewImage(this.image, {super.key});

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final images = await Permission.photos.request();
      return images.isGranted;
    } else {
      return true;
    }
  }

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      ImageProvider provider = image.image;
      Uint8List? bytes;

      // Unwrap ResizeImage if necessary
      if (provider is ResizeImage) {
        provider = provider.imageProvider;
      }

      if (provider is AssetImage) {
        final byteData = await rootBundle.load(provider.assetName);
        bytes = byteData.buffer.asUint8List();
      } else if (provider is MemoryImage) {
        bytes = provider.bytes;
      } else if (provider is FileImage) {
        bytes = await provider.file.readAsBytes();
      } else {
        snackBarError(context, 'Unsupported image type for saving.');
        return;
      }

      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        snackBarError(context, 'Storage permission denied.');
        return;
      }

      final directory = Directory('/storage/emulated/0/Download/Taulight');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      snackBarError(context, "Cannot save to gallery");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InteractiveViewer(
            maxScale: 5.0,
            minScale: 0.5,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: Center(child: image),
            ),
          ),
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back',
                  onPressed: () => Navigator.pop(context),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'save') {
                      _saveToGallery(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'save',
                      child: Text('Save to Gallery'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
