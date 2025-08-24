import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/auth_state.dart';
import 'package:taulight/main_screens/main_screen.dart';
import 'package:taulight/services/platform/chats.dart';
import 'package:taulight/widgets/client_dropdown.dart';
import 'package:taulight/widgets/flat_rect_button.dart';
import 'package:taulight/widgets/tau_app_bar.dart';

class CreateGroupScreen extends StatefulWidget implements IMainScreen {
  const CreateGroupScreen({super.key});

  @override
  IconData icon() => Icons.add_box_outlined;
  @override
  String title() => "Create group";

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends AuthState<CreateGroupScreen> {
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

  void _createGroup() async {
    if (_formKey.currentState!.validate()) {
      try {
        final title = _titleController.text.trim();

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

        final chatID = await PlatformChatsService.ins
            .createGroup(client, title)
            .timeout(Duration(seconds: 10));
        await client.loadChat(chatID).timeout(Duration(seconds: 10));

        if (mounted) {
          Navigator.pop(context, "success");
        }
      } catch (e, stackTrace) {
        print(e);
        print(stackTrace);
        setState(() => _error = "Failed to create group");
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
      appBar: TauAppBar.text("Create Group"),
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
                decoration: const InputDecoration(labelText: "Group title"),
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
              FlatRectButton(
                label: "Create",
                loading: _isLoading,
                onPressed: _createGroup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
