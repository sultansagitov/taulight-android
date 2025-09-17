import 'dart:io';
import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/file_messages.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/tau_button.dart';
import 'package:taulight/widgets/tau_loading.dart';

class MessageFilesWidget extends StatelessWidget {
  final TauChat chat;
  final ChatMessageViewDTO message;

  const MessageFilesWidget(this.chat, this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final files = message.files;
    if (files.isEmpty) return const SizedBox.shrink();

    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;

    final imageFiles =
        files.where((f) => f.contentType.startsWith('image/')).toList();
    final otherFiles =
        files.where((f) => !f.contentType.startsWith('image/')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageFiles.isNotEmpty) ...[
          _ImageGrid(chat: chat, files: imageFiles),
          const SizedBox(height: 10)
        ],
        if (otherFiles.isNotEmpty)
          ...otherFiles.map((file) =>
              _DownloadFileRow(chat: chat, file: file, textColor: textColor)),
      ],
    );
  }
}

class _ImageGrid extends StatefulWidget {
  final TauChat chat;
  final List<NamedFileDTO> files;

  const _ImageGrid({required this.chat, required this.files});

  @override
  State<_ImageGrid> createState() => _ImageGridState();
}

class _ImageGridState extends State<_ImageGrid> {
  late Future<List<_ImageFileStatus>> _statusesFuture;

  @override
  void initState() {
    super.initState();
    _statusesFuture = _loadImageStatuses();
  }

  Future<void> _refreshStatuses() async {
    final newStatuses = await _loadImageStatuses();
    setState(() {
      _statusesFuture = Future.value(newStatuses);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ImageFileStatus>>(
      future: _statusesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final statuses = snapshot.data!;
        final itemCount = statuses.length;

        int crossAxisCount;
        if (itemCount == 1) {
          crossAxisCount = 1;
        } else if (itemCount == 2) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final status = statuses[index];

            return GestureDetector(
              onTap: () async {
                if (status.isDownloaded && status.localPath != null) {
                  // If already downloaded, preview the image
                  final file = File(status.localPath!);
                  if (await file.exists()) {
                    await previewImage(context, Image.file(file));
                    return;
                  }
                }

                // Else, download
                setState(() => status.isLoading = true);
                try {
                  await FileMessageService.ins.downloadAndSaveFile(
                    widget.chat.client,
                    status.file,
                  );
                  snackBar(context, 'Image saved');
                  await _refreshStatuses();
                } catch (e, stackTrace) {
                  print(e);
                  print(stackTrace);
                  snackBarError(context, 'Download failed');
                }
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: status.isDownloaded && status.localPath != null
                          ? Image.file(
                              File(status.localPath!),
                              key: ValueKey('image_${status.localPath}'),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Container(
                              key: const ValueKey('placeholder'),
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.download,
                                  size: 36,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (!status.isDownloaded && status.isLoading)
                    const Positioned.fill(
                      child: Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: TauLoading(),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<_ImageFileStatus>> _loadImageStatuses() async {
    final List<_ImageFileStatus> result = [];

    for (final file in widget.files) {
      String? path = await FileMessageService.ins.getLocalPathForFile(file.id!);

      if (path == null || !File(path).existsSync()) {
        final fallbackPath =
            await FileMessageService.ins.getLocalFilePath(file);
        if (File(fallbackPath).existsSync()) {
          path = fallbackPath;
        } else {
          path = null;
        }
      }

      result.add(_ImageFileStatus(
        file: file,
        isDownloaded: path != null,
        localPath: path,
      ));
    }

    return result;
  }
}

class _ImageFileStatus {
  final NamedFileDTO file;
  final bool isDownloaded;
  final String? localPath;
  bool isLoading;

  _ImageFileStatus({
    required this.file,
    required this.isDownloaded,
    required this.localPath,
    this.isLoading = false,
  });
}

class _DownloadFileRow extends StatefulWidget {
  final TauChat chat;
  final NamedFileDTO file;
  final Color textColor;

  const _DownloadFileRow({
    required this.chat,
    required this.file,
    required this.textColor,
  });

  @override
  State<_DownloadFileRow> createState() => _DownloadFileRowState();
}

class _DownloadFileRowState extends State<_DownloadFileRow> {
  bool isLoading = false;
  bool isDownloaded = false;
  String? localFilePath;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    final downloaded =
        await FileMessageService.ins.isFileDownloaded(widget.file);
    if (!mounted) return;

    if (downloaded) {
      final path = await FileMessageService.ins.getLocalFilePath(widget.file);
      setState(() {
        isDownloaded = true;
        localFilePath = path;
      });
    }
  }

  Future<void> _downloadFile() async {
    setState(() => isLoading = true);
    final granted =
        await FileMessageService.ins.requestStoragePermission(context);
    if (!granted) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final path = await FileMessageService.ins
          .downloadAndSaveFile(widget.chat.client, widget.file);
      if (!mounted) return;

      setState(() {
        isDownloaded = true;
        localFilePath = path;
        isLoading = false;
      });

      snackBar(context, 'File saved to $path');
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      snackBarError(context, 'File not saved');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _openFile() async {
    try {
      await FileMessageService.ins.openFile(widget.file);
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      snackBarError(context, 'File opening error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.file.contentType.startsWith('image/');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isImage ? Icons.image : Icons.insert_drive_file,
            size: 20,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.file.filename,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: widget.textColor),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: TauLoading(),
            )
          else if (isDownloaded)
            TauButton.icon(
              Icons.open_in_new,
              color: Colors.green,
              onPressed: _openFile,
            )
          else
            TauButton.icon(
              Icons.download,
              color: Colors.blue,
              onPressed: _downloadFile,
            ),
        ],
      ),
    );
  }
}
