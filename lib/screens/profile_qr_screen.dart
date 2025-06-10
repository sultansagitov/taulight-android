import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/key_storage_service.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';

class ProfileQRScreen extends StatelessWidget {
  final Client client;

  const ProfileQRScreen({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    final address = client.address;
    final nickname = client.user!.nickname;
    final keyID = client.user!.keyID;

    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<Map<String, String>?>(
        future: KeyStorageService.ins.loadPersonalKey(address, keyID),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print(snapshot.error);
            print(snapshot.stackTrace);
            return const Center(child: Text("Key loading error"));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final Map<String, String> data = Map.from(snapshot.data!);

          data.remove("private");

          data["nickname"] = nickname;
          data['key-id'] = keyID;

          final uri = Uri(
            scheme: 'sandnode',
            userInfo: 'member',
            host: address,
            path: '/$nickname',
            queryParameters: data,
          );

          final String link = uri.toString();

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(32),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: link,
                        version: QrVersions.auto,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MyAvatar(client: client, d: 40),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Text(
                              nickname,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: getRandomColor(nickname),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
