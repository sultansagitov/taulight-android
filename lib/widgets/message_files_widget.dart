import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/file_message_service.dart';
import 'package:taulight/widget_utils.dart';

class MessageFilesWidget extends StatelessWidget {
  final TauChat chat;
  final ChatMessageViewDTO message;

  const MessageFilesWidget(this.chat, this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;

    final files = message.files;
    if (files.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: files.map((file) {
        return _DownloadFileRow(
          chat: chat,
          file: file,
          textColor: textColor,
        );
      }).toList(),
    );
  }
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
    _initFileStatus();
  }

  Future<void> _initFileStatus() async {
    final isSaved = await FileMessageService.ins.isFileDownloaded(widget.file);
    if (!mounted) return;

    if (isSaved) {
      final path = await FileMessageService.ins.getLocalFilePath(widget.file);
      setState(() {
        isDownloaded = true;
        localFilePath = path;
      });
    }
  }

  Future<void> _downloadFile() async {
    setState(() => isLoading = true);

    final granted = await FileMessageService.ins.requestStoragePermission(context);
    if (!granted) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final client = widget.chat.client;
      final path = await FileMessageService.ins.downloadAndSaveFile(client, widget.file);
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
      if (mounted) {
        snackBarError(context, 'File not saved');
        setState(() => isLoading = false);
      }
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, size: 20, color: Colors.blue),
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
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isDownloaded)
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.green),
              tooltip: 'Открыть файл',
              onPressed: _openFile,
            )
          else
            IconButton(
              icon: const Icon(Icons.download, color: Colors.blue),
              tooltip: 'Скачать файл',
              onPressed: _downloadFile,
            ),
        ],
      ),
    );
  }
}
