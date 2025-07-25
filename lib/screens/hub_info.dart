import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/screens/hubs.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
import 'package:taulight/widgets/tau_button.dart';

class HubInfoScreen extends StatefulWidget {
  final Client client;
  const HubInfoScreen(this.client, {super.key});

  @override
  State<HubInfoScreen> createState() => _HubInfoScreenState();
}

class _HubInfoScreenState extends State<HubInfoScreen> {
  Future<void> showQR(BuildContext context, double size) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: size,
          height: size,
          child: QrImageView(
            data: widget.client.link,
            version: QrVersions.auto,
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var status = widget.client.status;

    return Scaffold(
      appBar: TauAppBar.empty(actions: [
        TauButton.icon(Icons.qr_code, onPressed: () {
          showQR(context, size.width * 0.6);
        }),
        TauButton.icon(Icons.share, onPressed: () {
          SharePlus.instance.share(ShareParams(
            text: widget.client.link,
            subject: 'Check out this Hub',
          ));
        }),
      ]),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            widget.client.name,
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
                if (widget.client.realName != null)
                  _info(context, "Hub name", widget.client.name),
                _info(context, "Link", widget.client.link),
                if (widget.client.user != null)
                  HubsScreenState.buildMember(
                    context,
                    widget.client,
                    update: () => setState(() {}),
                  ),
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
