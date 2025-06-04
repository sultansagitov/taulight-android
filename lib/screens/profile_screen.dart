import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/profile_avatar_service.dart';
import 'package:taulight/widgets/login_list.dart';
import 'package:taulight/widgets/tau_button.dart';
import 'package:taulight/widgets/tip.dart';

class ProfileScreen extends StatefulWidget {
  final Client client;

  const ProfileScreen(this.client, {super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String nickname = "FlutterFan";
  final String bio = "Just a dev exploring the widget tree";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          TauButton.icon(
            Icons.qr_code,
            onPressed: () => showQR(context, size.width * 0.6),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            FutureBuilder(
                future: ProfileAvatarService.ins.getAvatar(widget.client),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print(snapshot.error);
                    print(snapshot.stackTrace);
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.data == null) {
                    return CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.deepOrange,
                    );
                  }

                  return CircleAvatar(
                    radius: 100,
                    child: Image.memory(
                      snapshot.data!.bytes,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  );
                }),
            const SizedBox(height: 16),
            Text(
              widget.client.user!.nickname,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(bio,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Login History", style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Tip("The IP address and device name, "
                "except for the timestamp, are encrypted on the "
                "server to ensure data security."),
            const SizedBox(height: 8),
            LoginList(widget.client),
          ],
        ),
      ),
    );
  }

  Future showQR(BuildContext context, double size) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            width: size,
            height: size,
            child: QrImageView(
              data: widget.client.user!.nickname,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
