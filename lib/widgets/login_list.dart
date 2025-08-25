import 'package:flutter/material.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/login_history_dto.dart';
import 'package:taulight/services/platform/agent.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widgets/tau_loading.dart';

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
    _loginHistory = PlatformAgentService.ins.loginHistory(widget.client);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LoginHistoryDTO>>(
      future: _loginHistory,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: TauLoading());
        } else if (snapshot.hasError) {
          print(snapshot.error);
          print(snapshot.stackTrace);
          return Center(child: Text('Error while loading history'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No login history found.'));
        }

        final logins = snapshot.data!;
        logins.sort((a, b) => a.time.compareTo(b.time));

        return Column(
          children: logins.map((login) {
            return ListTile(
              title: Row(
                children: [
                  Text(formatTime(login.time)),
                  if (login.online) ...[
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        color: Colors.green.withAlpha(64),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          child: Text("Active"),
                        ),
                      ),
                    )
                  ]
                ],
              ),
              subtitle: Text('IP: ${login.ip} | Device: ${login.device}'),
              leading: const Icon(Icons.login),
            );
          }).toList(),
        );
      },
    );
  }
}
