import 'package:flutter/material.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widget_utils.dart';

class ChannelInfoScreen extends StatelessWidget {
  final TauChat chat;

  const ChannelInfoScreen(this.chat, {super.key});

  @override
  Widget build(BuildContext context) {
    final record = chat.record as ChannelRecord;
    final Future<List<Member>?> membersFuture = _fetchMembers();

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(record.title),
      ),
      body: chat.client.connected
          ? _buildMemberList(membersFuture, record, context)
          : _buildInfo(),
    );
  }

  Future<List<Member>?> _fetchMembers() async {
    if (chat.client.connected) {
      return await chat.getMembers();
    }
    return null;
  }

  Widget _buildAppBarTitle(String title) {
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Colors.black,
          radius: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberList(
    Future<List<Member>?> membersFuture,
    ChannelRecord record,
    BuildContext context,
  ) {
    return FutureBuilder<List<Member>?>(
      future: membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
          return const Center(child: Text("No members found"));
        }

        final bool isLight = Theme.of(context).brightness == Brightness.light;
        final List<Member> members = snapshot.data!;
        final bool isOwner = chat.client.user != null &&
            chat.client.user!.nickname == record.owner;

        return ListView.builder(
          itemCount:
              members.length + 2, // +1 for info, +1 for add member button
          itemBuilder: (_, index) {
            if (index == 0) {
              return _buildInfo(members);
            }

            // Add member button as the first item after the info
            if (index == 1) {
              return isOwner ? _buildAddMemberTile(context) : const SizedBox();
            }

            final Member member =
                members[index - 2]; // -2 to account for info and add button
            final String role =
                member.nickname == record.owner ? "owner" : "member";

            Color color = getRandomColor(member.nickname);
            if (isLight) {
              color = dark(color);
            }

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.deepPurple,
              ),
              title: Text(
                member.nickname,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              subtitle: Text(member.status.name),
              trailing: Text(role),
            );
          },
        );
      },
    );
  }

  Widget _buildAddMemberTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.person_add),
      title: const Text(
        "Add member",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () => _showAddMemberDialog(context),
    );
  }

  Widget _buildInfo([List<Member>? members]) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text("Members count: ${members?.length ?? "Unknown"}"),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    List<TauChat> chats = chat.client.chats.values
        .where((chat) => chat.record is DialogRecord)
        .toList();

    moveTo(context, MembersInviteScreen(chats: chats, chatToInvite: chat));
  }
}

class MembersInviteScreen extends StatelessWidget {
  final List<TauChat> chats;
  final TauChat chatToInvite;

  const MembersInviteScreen({
    super.key,
    required this.chats,
    required this.chatToInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send link to ...")),
      body: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: chats.length,
          itemBuilder: (context, index) {
            var chat = chats[index];
            var d = 52;
            final String nickname = (chat.record as DialogRecord).otherNickname;

            return InkWell(
              onTap: () async {
                if (nickname.isNotEmpty) {
                  try {
                    String code = await chatToInvite.addMember(nickname);

                    String endpoint = chatToInvite.client.endpoint;
                    String text = "sandnode://$endpoint/invite/$code";
                    await chat.sendMessage(text, [], () {});

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } on NoEffectException {
                    if (context.mounted) {
                      snackBar(context, "$nickname already in");
                    }
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: d.toDouble(),
                        height: d.toDouble(),
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat.getTitle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
