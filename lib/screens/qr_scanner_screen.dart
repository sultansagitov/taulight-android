import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: MobileScanner(
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
