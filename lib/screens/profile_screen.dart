import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/profile_avatar_service.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';
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
  final picker = ImagePicker();

  final String bio = "Just a dev exploring the widget tree";

  void _pickImage() async {
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    await ProfileAvatarService.ins.setAvatar(widget.client, file.path);
    setState(() {});
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

  Future<void> _showImagePreview(BuildContext context, Client client) async {
    var size = MediaQuery.of(context).size;

    var memoryImage = await ProfileAvatarService.ins.getAvatar(client);

    if (memoryImage == null) {
      return;
    }

    var image = Image.memory(memoryImage.bytes, fit: BoxFit.contain);

    var stack = Stack(children: [
      InteractiveViewer(
        child: Container(
          width: size.width,
          height: size.height,
          color: Colors.black,
          child: Center(child: image),
        ),
      ),
      SafeArea(
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    ]);

    await moveTo(context, stack);
    setState(() {});
  }

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
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: () => _showImagePreview(context, widget.client),
                  child: MyAvatar(client: widget.client, d: 200),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: Icon(Icons.edit, color: Colors.white, size: 20),
                      onPressed: _pickImage,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.client.user!.nickname,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              bio,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Login History", style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Tip("The IP addressand device name, "
                "except for the timestamp, are encrypted on the "
                "server to ensure data security."),
            const SizedBox(height: 8),
            LoginList(widget.client),
          ],
        ),
      ),
    );
  }
}
