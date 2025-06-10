import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/screens/profile_qr_screen.dart';
import 'package:taulight/services/profile_avatar_service.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/login_list.dart';
import 'package:taulight/widgets/show_status_settings.dart';
import 'package:taulight/widgets/tau_button.dart';
import 'package:taulight/widgets/tip.dart';

class ProfileScreen extends StatefulWidget {
  final Client client;

  const ProfileScreen(this.client, {super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, String>>? f;
  final picker = ImagePicker();

  final String bio = "Just a dev exploring the widget tree";

  bool showStatus = true; // placeholder value for setting

  void _pickImage() async {
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    await ProfileAvatarService.ins.setMy(widget.client, file.path);
    setState(() {});
  }

  Future<void> showQR(BuildContext context) async {
    await moveTo(context, ProfileQRScreen(client: widget.client));
    setState(() {});
  }

  Future<void> _showImagePreview(BuildContext context) async {
    var size = MediaQuery.of(context).size;
    var memoryImage = await ProfileAvatarService.ins.getMy(widget.client);
    if (memoryImage == null) return;

    var image = Image.memory(memoryImage.bytes, fit: BoxFit.contain);

    await previewImage(
      context: context,
      image: image,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          TauButton.icon(
            Icons.qr_code,
            onPressed: () => showQR(context),
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
                  onTap: () => _showImagePreview(context),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ShowStatusSettings(widget.client),
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
}
