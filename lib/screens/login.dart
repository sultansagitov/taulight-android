import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/widgets/tau_buton.dart';

class LoginScreen extends StatefulWidget {
  final Client client;
  final VoidCallback updateHome;
  final VoidCallback? onSuccess;

  const LoginScreen({
    super.key,
    required this.client,
    required this.updateHome,
    this.onSuccess,
  });

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegistering = false;
  String _errorMessage = '';

  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    var client = widget.client;

    setState(() => _errorMessage = '');

    var nickname = _nicknameController.text;
    var passwd = _passwordController.text;
    if (nickname.isEmpty || passwd.isEmpty) {
      setState(() => _errorMessage = "Incorrect username or password.");
      return;
    }

    try {
      setState(() => _loading = true);
      String token = await JavaService.instance.log(client, nickname, passwd);
      UserRecord userRecord = UserRecord(nickname, token);
      await StorageService.saveWithToken(client, userRecord);
      setState(() => _loading = false);
      widget.updateHome();
      if (mounted) Navigator.pop(context);
      if (widget.onSuccess != null) widget.onSuccess!();
    } on IncorrectUserDataException {
      setState(() {
        _errorMessage = "Incorrect username or password.";
        _loading = false;
      });
    } on DisconnectException {
      setState(() {
        _errorMessage = "Connection error. Try again.";
        _loading = false;
      });
    }
  }

  Future<void> _register() async {
    var client = widget.client;

    String nickname = _nicknameController.text;
    String passwd = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (passwd != confirmPassword) {
      setState(() => _errorMessage = "Passwords do not match.");
      return;
    }

    setState(() => _errorMessage = '');
    try {
      setState(() => _loading = true);
      String token = await JavaService.instance.reg(client, nickname, passwd);
      UserRecord userRecord = UserRecord(nickname, token);
      await StorageService.saveWithToken(client, userRecord);
      setState(() => _loading = false);
      widget.updateHome();
      if (mounted) {
        Navigator.pop(context);
      }
      if (widget.onSuccess != null) widget.onSuccess!();
    } on IncorrectUserDataException {
      setState(() {
        _errorMessage = "Invalid registration data.";
        _loading = false;
      });
    } on BusyNicknameException {
      setState(() {
        _errorMessage = "Nickname is busy.";
        _loading = false;
      });
    } on DisconnectException {
      setState(() {
        _errorMessage = "Connection error. Try again.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegistering ? "Register" : "Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(hintText: "Nickname"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: "Password",
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            if (_isRegistering) ...[
              SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscure,
                decoration: InputDecoration(hintText: "Confirm Password"),
              ),
            ],
            SizedBox(height: 10),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_loading) ...[
                  CircularProgressIndicator(),
                  const SizedBox(width: 10),
                ] else ...[
                  TauButton(
                    _isRegistering ? "Register" : "Login",
                    onPressed: _isRegistering ? _register : _login,
                  ),
                ],
              ],
            ),
            TauButton(
              _isRegistering
                  ? "Already have an account? Login"
                  : "Don't have an account? Register",
              style: BtnStyle.text,
              onPressed: () => setState(() => _isRegistering = !_isRegistering),
            ),
          ],
        ),
      ),
    );
  }
}
