import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:taulight/screens/home_screen.dart';
import 'package:taulight/services/storage_service.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  String _input = '';
  String _confirmInput = '';
  String? _storedPin;
  String? _firstPin;
  String? _errorText;

  bool _isSettingPin = false;
  bool _isConfirmingPin = false;
  bool _fingerprintEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _initPinFlow();
  }

  Future<void> _initPinFlow() async {
    try {
      final storedPin = await StorageService.ins.getPIN();
      final fingerprintEnabled = await StorageService.ins.getFingerprintEnabled() ?? false;

      final canCheckBiometrics = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();
      final biometricAvailable = canCheckBiometrics || isDeviceSupported;

      setState(() {
        _storedPin = storedPin;
        _fingerprintEnabled = fingerprintEnabled;
        _biometricAvailable = biometricAvailable;
        _isSettingPin = storedPin == null;
      });

      if (storedPin != null && fingerprintEnabled && biometricAvailable) {
        _authenticateWithBiometrics();
      }
    } catch (e, stackTrace) {
      print('Biometric check error: $e');
      print(stackTrace);
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuthenticate) _goToHome();
    } catch (e, stackTrace) {
      print('Biometric auth error: $e');
      print(stackTrace);
    }
  }

  void _onKeyTap(String value) {
    setState(() {
      if (_isSettingPin && _isConfirmingPin) {
        if (_confirmInput.length < 4) _confirmInput += value;
        if (_confirmInput.length == 4) _validateConfirmPin();
      } else {
        if (_input.length < 4) _input += value;
        if (_input.length == 4) _handlePinInput();
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_isSettingPin && _isConfirmingPin) {
        if (_confirmInput.isNotEmpty) {
          _confirmInput = _confirmInput.substring(0, _confirmInput.length - 1);
        }
      } else {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      }
    });
  }

  Future<void> _handlePinInput() async {
    if (_isSettingPin) {
      _firstPin = _input;
      _input = '';
      _isConfirmingPin = true;
    } else {
      if (_input == _storedPin) {
        _goToHome();
      } else {
        setState(() {
          _errorText = 'Incorrect PIN';
          _input = '';
        });
      }
    }
  }

  Future<void> _validateConfirmPin() async {
    if (_confirmInput == _firstPin) {
      await StorageService.ins.setPIN(_confirmInput);
      await _askToEnableFingerprint();
      _goToHome();
    } else {
      setState(() {
        _errorText = 'PINs do not match';
        _firstPin = null;
        _confirmInput = '';
        _isConfirmingPin = false;
      });
    }
  }

  Future<void> _askToEnableFingerprint() async {
    if (!_biometricAvailable) return;
    final enable = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enable Fingerprint?'),
        content: const Text('Would you like to use fingerprint authentication?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (enable == true) {
      await StorageService.ins.setFingerprintEnabled();
      setState(() => _fingerprintEnabled = true);
    } else {
      await StorageService.ins.setFingerprintDisabled();
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Widget _buildKeyboardButton(String value) {
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.surfaceContainerHighest;
  final textColor = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: () => _onKeyTap(value),
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _onDelete,
      child: const Icon(Icons.backspace, size: 28),
    );
  }

  Widget _buildFingerprintButton() {
    if (!_fingerprintEnabled || !_biometricAvailable) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _authenticateWithBiometrics,
      child: const Icon(Icons.fingerprint, size: 32),
    );
  }

  Widget _buildKeyboard() {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key == 'del') return Center(child: _buildDeleteButton());
        if (key == '') return Center(child: _buildFingerprintButton());
        return _buildKeyboardButton(key);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConfirming = _isSettingPin && _isConfirmingPin;
    final title = _isSettingPin
        ? (isConfirming ? "Confirm PIN" : "Set PIN")
        : "Enter PIN";

    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (isConfirming) ...[
                    _buildDots(_firstPin ?? '', context),
                    const SizedBox(height: 12),
                    _buildDots(_confirmInput, context),
                  ] else
                    _buildDots(_input, context),
                  if (_errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorText!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: _buildKeyboard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots(String value, BuildContext context) {
    final theme = Theme.of(context);
    final filledColor = theme.colorScheme.primary;
    final emptyColor = theme.dividerColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < value.length ? filledColor : emptyColor,
          ),
        );
      }),
    );
  }
}