import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/records.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/screens/members_invite_screen.dart';
import 'package:taulight/services/avatar_service.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';

class ChannelInfoScreen extends StatelessWidget {
  final TauChat chat;

  const ChannelInfoScreen(this.chat, {super.key});

  @override
  Widget build(BuildContext context) {
    final record = chat.record as ChannelDTO;
    final Future<List<Member>?> membersFuture = _fetchMembers();

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(context, record.title),
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

  Widget _buildAppBarTitle(BuildContext context, String title) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            _pickAndSetChannelAvatar(context, chat);
          },
          child: ChatAvatar(chat, d: 40),
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
    ChannelDTO record,
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
              leading: ChatAvatar(chat, d: 40),
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

  Future<void> _showAddMemberDialog(BuildContext context) async {
    var c = chat.client.chats.values.where(isDialog).toList();
    await moveTo(context, MembersInviteScreen(chats: c, chatToInvite: chat));
  }

  Future<void> _pickAndSetChannelAvatar(
      BuildContext context, TauChat chat) async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    await AvatarService.ins.setChannelAvatar(chat, pickedFile.path);
  }
}
