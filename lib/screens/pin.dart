import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:taulight/screens/home.dart';
import 'package:taulight/services/storage.dart';
import 'package:taulight/widget_utils.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final auth = LocalAuthentication();
  String _input = '', _confirm = '', _storedPin = '', _firstPin = '';
  String? _error;
  bool _setPin = false, _confirming = false, _finger = false, _bio = false;

  Color _monoColor(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? Colors.white : Colors.black;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final pin = await StorageService.ins.getPIN();
    final f = await StorageService.ins.getFingerprintEnabled() ?? false;
    final b = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    setState(() {
      _storedPin = pin ?? '';
      _finger = f;
      _bio = b;
      _setPin = pin == null;
    });
    if (pin != null && f && b) _auth();
  }

  Future<void> _auth() async {
    bool success = await auth.authenticate(
      localizedReason: 'Auth',
      options: const AuthenticationOptions(biometricOnly: true),
    );
    if (success) _goHome();
  }

  void _key(String v) {
    setState(() {
      if (_setPin && _confirming) {
        if (_confirm.length < 4) _confirm += v;
        if (_confirm.length == 4) _checkConfirm();
      } else {
        if (_input.length < 4) _input += v;
        if (_input.length == 4) _checkInput();
      }
    });
  }

  void _del() {
    setState(() {
      if (_setPin && _confirming && _confirm.isNotEmpty) {
        _confirm = _confirm.substring(0, _confirm.length - 1);
      } else if (_input.isNotEmpty) {
        _input = _input.substring(0, _input.length - 1);
      }
    });
  }

  Future<void> _checkInput() async {
    if (_setPin) {
      _firstPin = _input;
      _input = '';
      _confirming = true;
    } else if (_input == _storedPin) {
      _goHome();
    } else {
      setState(() {
        _error = 'Incorrect PIN';
        _input = '';
      });
    }
  }

  Future<void> _checkConfirm() async {
    if (_confirm == _firstPin) {
      await StorageService.ins.setPIN(_confirm);
      await _askFinger();
      _goHome();
    } else {
      setState(() {
        _error = 'Mismatch';
        _firstPin = '';
        _confirm = '';
        _confirming = false;
      });
    }
  }

  Future<void> _askFinger() async {
    if (!_bio) return;
    final e = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enable Fingerprint?'),
        content:
            const Text('Would you like to use fingerprint authentication?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (e == true) {
      await StorageService.ins.setFingerprintEnabled();
      setState(() => _finger = true);
    } else {
      await StorageService.ins.setFingerprintDisabled();
    }
  }

  void _goHome() => moveTo(
        context,
        const HomeScreen(),
        fromBottom: true,
        canReturn: false,
      );

  Widget _btn(String v) {
    return GestureDetector(
      onTap: () => _key(v),
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _monoColor(context).withValues(alpha: 0.1),
        ),
        alignment: Alignment.center,
        child: Text(
          v,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _monoColor(context)),
        ),
      ),
    );
  }

  Widget _dots(String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < v.length ? _monoColor(context) : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final title =
        _setPin ? (_confirming ? 'Confirm PIN' : 'Set PIN') : 'Enter PIN';
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 60),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _monoColor(ctx),
            ),
          ),
          const SizedBox(height: 30),
          _setPin && _confirming
              ? Column(children: [
                  _dots(_firstPin),
                  const SizedBox(height: 12),
                  _dots(_confirm)
                ])
              : _dots(_input),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const Spacer(),
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3),
            itemBuilder: (_, i) {
              const keys = [
                '1',
                '2',
                '3',
                '4',
                '5',
                '6',
                '7',
                '8',
                '9',
                '',
                '0',
                'del'
              ];
              final k = keys[i];
              if (k == 'del') {
                return IconButton(
                  onPressed: _del,
                  icon: const Icon(Icons.backspace),
                );
              }
              if (k == '' && _finger && _bio) {
                return IconButton(
                  onPressed: _auth,
                  icon: const Icon(Icons.fingerprint),
                );
              }
              if (k == '') return const SizedBox.shrink();
              return _btn(k);
            },
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}
