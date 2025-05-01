import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/auth_state.dart';
import 'package:taulight/widgets/client_dropdown.dart';
import 'package:taulight/widgets/tau_button.dart';

class CreateChannelScreen extends StatefulWidget {
  final VoidCallback callback;

  const CreateChannelScreen({super.key, required this.callback});

  @override
  State<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends AuthState<CreateChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _controller = ClientDropdownController();

  String? _error;
  bool _isLoading = false;
  bool _titleFieldEnabled = true;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _createChannel() async {
    if (_formKey.currentState!.validate()) {
      try {
        final title = _titleController.text;

        setState(() {
          _error = null;
          _isLoading = true;
          _titleFieldEnabled = false;
        });

        Client? client = _controller.client;

        if (client == null) {
          setState(() => _error = "Please select a client.");
          return;
        }

        if (!client.connected) {
          setState(() => _error = "Disconnected from client");
          return;
        }

        final chatID =
            await client.createChannel(title).timeout(Duration(seconds: 10));
        await client.loadChat(chatID).timeout(Duration(seconds: 10));

        widget.callback();

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _error = "Failed to create channel");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _titleFieldEnabled = true;
          });
        }
      }
    }
  }

  @override
  Widget authorizedBuild(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Channel")),
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
                enabled: _titleFieldEnabled,
                decoration: const InputDecoration(labelText: "Channel title"),
                validator: (value) => value == null || value.isEmpty
                    ? "Title field cannot be empty"
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
              TauButton.text(
                "Create",
                loading: _isLoading,
                onPressed: _createChannel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
