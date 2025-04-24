import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/java_service.dart';
import 'package:taulight/widgets/client_dropdown.dart';

void dialogDialog(BuildContext context, VoidCallback callback) {
  showDialog(
    context: context,
    builder: (context) {
      final titleController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      List<Client> clientsList = JavaService.instance.clients.values
          .where((c) => c.user != null && c.user!.authorized)
          .toList();
      Client? currClient;

      String? error;

      return AlertDialog(
        shape: const LinearBorder(),
        title: const Text(
          "Start dialog",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClientDropdown(
                clients: clientsList,
                onClientChanged: (client) => currClient = client,
              ),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Dialog"),
                validator: (value) {
                  if (error != null) return error;

                  if (value == null || value.isEmpty) {
                    return "Title cannot be empty";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Start"),
            onPressed: () async {
              error = null;

              if (!formKey.currentState!.validate()) return;

              if (currClient == null) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: const LinearBorder(),
                    title: const Text("Error"),
                    content: const Text("Please select a client."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
                return;
              }

              var nickname = titleController.text;
              try {
                await currClient!.createDialog(nickname);
              } on AddressedMemberNotFoundException {
                error = "Member $nickname not found";
                formKey.currentState!.validate();
                return;
              }

              callback();

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      );
    },
  );
}
