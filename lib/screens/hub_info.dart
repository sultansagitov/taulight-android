import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/screens/login.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/flat_rect_button.dart';
import 'package:taulight/widgets/member_item.dart';
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
            data: widget.client.link!,
            version: QrVersions.auto,
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final status = widget.client.status;

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
        mainAxisAlignment: MainAxisAlignment.center,
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
                if (widget.client.user != null)
                  MemberItem(
                    client: widget.client,
                    onUpdated: () => setState(() {}),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: FlatRectButton(
                      icon: Icons.login,
                      label: "Login",
                      width: double.infinity,
                      onPressed: () async {
                        final screen = LoginScreen(client: widget.client);
                        await moveTo(context, screen);
                        setState(() {});
                      },
                    ),
                  ),
                if (widget.client.realName != null)
                  _info(context, "Hub name", widget.client.name),
                if (widget.client.link != null)
                  _info(context, "Link", widget.client.link!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _info(BuildContext context, String key, String value) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bgColor = isDark ? const Color(0xFF2F2F2F) : Colors.grey.shade200;
  final primaryTextColor = isDark ? Colors.white : Colors.black;
  final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

  return GestureDetector(
    onLongPress: () => copy(context, value),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$key: $value",
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Hold to copy",
            style: TextStyle(
              fontSize: 12,
              color: secondaryTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ),
  );
}
