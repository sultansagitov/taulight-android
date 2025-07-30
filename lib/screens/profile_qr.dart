import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/keys.dart';
import 'package:taulight/services/key_storages.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

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

    return Scaffold(
      appBar: TauAppBar.empty(),
      body: FutureBuilder<PersonalKey>(
        future: KeyStorageService.ins.loadPersonalKey(
          address: address,
          nickname: nickname,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print(snapshot.error);
            print(snapshot.stackTrace);
            return const Center(child: Text("Key loading error"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          PersonalKey personalKey = snapshot.data!;
          final Map<String, String> data = {
            'nickname': nickname,
            'encryption': personalKey.encryption,
            if (personalKey.symKey != null) 'sym': personalKey.symKey!,
            if (personalKey.publicKey != null) 'public': personalKey.publicKey!,
          };

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
