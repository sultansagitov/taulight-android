import 'package:flutter/material.dart';
import 'package:taulight/classes/chat_message_view_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/file_service.dart';
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

  Future<void> _downloadFile() async {
    setState(() {
      isLoading = true;
      isDownloaded = false;
    });

    final granted = await FileService.ins.requestStoragePermission(context);
    if (!granted) return;

    String? filePath;
    try {
      Client client = widget.chat.client;
      filePath = await FileService.ins.downloadAndSaveFile(client, widget.file);
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      snackBarError(context, 'Download failed: $e');
      return;
    }

    if (filePath != null && context.mounted) {
      setState(() => isDownloaded = true);
      snackBar(context, 'File saved to $filePath');
    }

    if (context.mounted) {
      setState(() => isLoading = false);
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
            const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else
            IconButton(
              icon: const Icon(Icons.download, color: Colors.blue),
              onPressed: _downloadFile,
            ),
        ],
      ),
    );
  }
}
