import 'package:flutter/material.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/auth_state.dart';
import 'package:taulight/widgets/client_dropdown.dart';
import 'package:taulight/widgets/tau_button.dart';

class StartDialogScreen extends StatefulWidget {
  const StartDialogScreen({super.key});

  @override
  State<StartDialogScreen> createState() => _StartDialogScreenState();
}

class _StartDialogScreenState extends AuthState<StartDialogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _controller = ClientDropdownController();

  String? _error;
  bool _isLoading = false;
  bool _fieldEnabled = true;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _startDialog() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    var client = _controller.client;
    if (client == null) {
      setState(() {
        _isLoading = false;
        _error = "Please select a client.";
      });
      return;
    }

    setState(() => _fieldEnabled = false);
    final nickname = _titleController.text.trim();

    try {
      await client.createDialog(nickname).timeout(Duration(seconds: 10));
    } on AddressedMemberNotFoundException {
      setState(() {
        _error = "Member $nickname not found";
        _isLoading = false;
      });
      _formKey.currentState!.validate();
      return;
    } finally {
      if (mounted) {
        setState(() {
          _fieldEnabled = true;
          _isLoading = false;
        });
      }
    }

    if (mounted) {
      Navigator.pop(context, nickname);
    }
  }

  @override
  Widget authorizedBuild(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Start Dialog")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ClientDropdown(controller: _controller),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Dialog"),
                enabled: _fieldEnabled,
                validator: (value) => value == null || value.isEmpty
                    ? "Nickname field cannot be empty"
                    : null,
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Align(
                  alignment: Alignment.center,
                  child: Text(_error!, style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 6),
              ],
              SizedBox(
                width: double.infinity,
                child: TauButton.text(
                  "Start",
                  loading: _isLoading,
                  onPressed: _startDialog,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
