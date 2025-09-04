import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/keys.dart';
import 'package:taulight/classes/nickname.dart';
import 'package:taulight/classes/sources.dart';
import 'package:taulight/services/key_storages.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widgets/tau_button.dart';

class QRExchangeScreen extends StatefulWidget {
  final Client client;
  final Nickname other;

  const QRExchangeScreen({
    super.key,
    required this.client,
    required this.other,
  });

  @override
  State<QRExchangeScreen> createState() => _QRExchangeScreenState();
}

class _QRExchangeScreenState extends State<QRExchangeScreen> {
  final MobileScannerController _controller =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);

  String? _myQR;
  String? _result;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _loadMyQR();
  }

  Future<void> _loadMyQR() async {
    try {
      final myNick = widget.client.user!.nickname;
      final pk = await KeyStorageService.ins.loadPersonalKey(
        address: widget.client.address,
        nickname: myNick,
      );
      _myQR = jsonEncode({
        "nickname": myNick,
        "encryption": pk.encryption,
        if (pk.symKey != null) "sym": pk.symKey!,
        if (pk.publicKey != null) "public": pk.publicKey!,
      });
    } catch (e) {
      _result = "Error loading personal key";
    }
    if (mounted) setState(() {});
  }

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_locked) return;
    final raw = cap.barcodes.isNotEmpty ? cap.barcodes.first.rawValue : null;
    if (raw == null) return;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final nick = map["nickname"] as String?;
      final enc = map["encryption"] as String?;
      final pub = map["public"] as String?;
      final sym = map["sym"] as String?;

      if (nick == null || enc == null || (pub == null && sym == null)) {
        _result = "Invalid QR";
      } else {
        final nickname = Nickname.checked(nick);
        try {
          final stored = await KeyStorageService.ins.loadEncryptor(
            address: widget.client.address,
            nickname: nickname,
          );
          final match = (stored.encryption == enc) &&
              ((stored.publicKey ?? "") == (pub ?? "")) &&
              ((stored.symKey ?? "") == (sym ?? ""));
          _result = match
              ? "✅ $nickname matches stored key"
              : "❌ $nickname does not match stored key";
        } catch (_) {
          final ek = EncryptorKey(
            nickname: nickname,
            address: widget.client.address,
            encryption: enc,
            publicKey: pub,
            symKey: sym,
            source: QRSource(),
          );
          await KeyStorageService.ins.saveEncryptor(ek);
          _result = "ℹ Saved new encryptor for $nickname";
        }

        if (nickname == widget.other) {
          _result = "[Profile: ${widget.other}]\n$_result";
        }
      }
    } catch (_) {
      _result = "Parse error";
    }

    _locked = true;
    if (mounted) setState(() {});

    try {
      await _controller.stop();
    } catch (_) {}
  }

  Future<void> _reset() async {
    _locked = false;
    _result = null;
    if (mounted) setState(() {});

    try {
      await _controller.stop();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 250));
    try {
      await _controller.start();
    } catch (_) {}
  }

  Widget _buildQR() {
    if (_myQR == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final myNick = widget.client.user!.nickname;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxHeight * 0.78;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: _myQR!,
              version: QrVersions.auto,
              size: size,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 8),
            MemberAvatar(client: widget.client, nickname: myNick, d: 40),
            Text(
              myNick.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: getRandomColor(myNick.toString()),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TauAppBar(
        title: const Text("QR Exchange"),
        actions: [
          TauButton.icon(
            Icons.flash_on,
            onPressed: () => _controller.toggleTorch(),
          ),
          TauButton.icon(
            Icons.cameraswitch,
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                if (_result != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      color: Colors.black54,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_result!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                          TextButton(
                            onPressed: () => _reset(),
                            child: const Text("Scan again",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildQR()),
        ],
      ),
    );
  }
}
