import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/login_history_dto.dart';
import 'package:taulight/services/platform_service.dart';
import 'package:taulight/utils.dart';

class LoginList extends StatefulWidget {
  final Client client;

  const LoginList(this.client, {super.key});

  @override
  State<LoginList> createState() => _LoginListState();
}

class _LoginListState extends State<LoginList> {
  late final Future<List<LoginHistoryDTO>> _loginHistory;

  @override
  void initState() {
    super.initState();
    _loginHistory = PlatformService.ins.loginHistory(widget.client);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LoginHistoryDTO>>(
      future: _loginHistory,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No login history found.'));
        }

        final logins = snapshot.data!;

        return Column(
          children: logins.map((login) {
            return ListTile(
              title: Text(formatTime(login.time)),
              subtitle: Text('IP: ${login.ip} | Device: ${login.device}'),
              leading: const Icon(Icons.login),
            );
          }).toList(),
        );
      },
    );
  }
}
