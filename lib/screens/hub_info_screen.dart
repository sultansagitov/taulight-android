import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/widget_utils.dart';

class HubInfoScreen extends StatelessWidget {
  final Client client;
  const HubInfoScreen(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    var status = client.status;

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: client.link,
            version: QrVersions.auto,
            size: size.width * 0.8,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            client.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            status.str,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: status.color.withAlpha(192),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (client.realName != null)
                  _info(context, "Hub name", client.name),
                _info(context, "Link", client.link),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _info(BuildContext context, String key, String value) {
  bool isLight = Theme.of(context).brightness == Brightness.light;
  return GestureDetector(
    onLongPress: () {
      Clipboard.setData(ClipboardData(text: value));
      snackBar(context, "$key copied");
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$key: $value",
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Hold to copy",
            style: TextStyle(
              fontSize: 12,
              color: isLight ? Colors.black54 : Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ),
  );
}
