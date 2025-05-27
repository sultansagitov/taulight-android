import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/services/platform_service.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/storage_service.dart';
import 'package:taulight/widgets/tau_button.dart';

class LoginScreen extends StatefulWidget {
  final Client client;

  const LoginScreen({
    super.key,
    required this.client,
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
    Client client = widget.client;

    setState(() => _errorMessage = '');

    var nickname = _nicknameController.text.trim();
    var passwd = _passwordController.text.trim();
    if (nickname.isEmpty) {
      setState(() => _errorMessage = "Please enter nickname");
      return;
    }

    if (passwd.isEmpty) {
      setState(() => _errorMessage = "Please enter password");
      return;
    }

    try {
      setState(() => _loading = true);
      await PlatformService.ins.log(client, nickname, passwd);
      setState(() => _loading = false);
      if (mounted) Navigator.pop(context, "login-success");
    } on IncorrectUserDataException {
      _errorMessage = "Incorrect username or password.";
    } on DisconnectException {
      _errorMessage = "Connection error. Try again.";
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      _errorMessage = "Unknown error. Try again.";
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    var client = widget.client;

    String nickname = _nicknameController.text.trim();
    String passwd = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (nickname.isEmpty) {
      setState(() => _errorMessage = "Please enter nickname");
      return;
    }

    if (passwd.isEmpty) {
      setState(() => _errorMessage = "Please enter password");
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() => _errorMessage = "Please enter password");
      return;
    }

    if (passwd != confirmPassword) {
      setState(() => _errorMessage = "Passwords do not match.");
      return;
    }

    setState(() => _errorMessage = '');
    try {
      setState(() => _loading = true);
      String token = await PlatformService.ins.reg(client, nickname, passwd);
      UserRecord userRecord = UserRecord(nickname, token);
      await StorageService.ins.saveWithToken(client, userRecord);
      setState(() => _loading = false);
      if (mounted) {
        Navigator.pop(context, "register-success");
      }
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
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      setState(() {
        _errorMessage = "Unknown error. Try again.";
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
                suffixIcon: TauButton.icon(
                  _obscure ? Icons.visibility : Icons.visibility_off,
                  onPressed: () => setState(() => _obscure = !_obscure),
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
                TauButton.text(
                  _isRegistering ? "Register" : "Login",
                  onPressed: _isRegistering ? _register : _login,
                  loading: _loading,
                ),
              ],
            ),
            TauButton.text(
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
