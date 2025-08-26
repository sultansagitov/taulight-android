import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
import 'package:taulight/widgets/tau_button.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TauAppBar.text(
        "Scan QR Code",
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
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_hasScanned) return;
          for (final barcode in capture.barcodes) {
            final String? code = barcode.rawValue;
            if (code != null && code.startsWith("sandnode:")) {
              setState(() => _hasScanned = true);
              Navigator.pop(context, code);
              break;
            }
          }
        },
      ),
    );
  }
}
