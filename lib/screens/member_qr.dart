import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/keys.dart';
import 'package:taulight/services/key_storages.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
import 'package:taulight/widgets/tau_loading.dart';

class MemberQRScreen extends StatelessWidget {
  final Client client;
  final String nickname;

  const MemberQRScreen({
    super.key,
    required this.client,
    required this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    final address = client.address;

    return Scaffold(
      appBar: TauAppBar.empty(),
      body: FutureBuilder<EncryptorKey>(
        future: KeyStorageService.ins.loadEncryptor(
          address: address,
          nickname: nickname,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print(snapshot.error);
            print(snapshot.stackTrace);
            return Center(
              child: Text(
                "You didn’t receive a key, you’re using your own",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: TauLoading());
          }

          final encryptor = snapshot.data!;
          final Map<String, String> data = {
            'nickname': nickname,
            'encryption': encryptor.encryption,
            if (encryptor.symKey != null) 'sym': encryptor.symKey!,
            if (encryptor.publicKey != null) 'public': encryptor.publicKey!,
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
                          MemberAvatar(
                              client: client, nickname: nickname, d: 40),
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
