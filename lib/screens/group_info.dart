import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/chat_member.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/role_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/uuid.dart';
import 'package:taulight/screens/member_info.dart';
import 'package:taulight/screens/members_invite.dart';
import 'package:taulight/screens/profile.dart';
import 'package:taulight/services/chat_avatar.dart';
import 'package:taulight/services/platform/chats.dart';
import 'package:taulight/services/platform/role.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';
import 'package:taulight/widgets/tau_app_bar.dart';
import 'package:taulight/widgets/tau_loading.dart';

class GroupInfoScreen extends StatefulWidget {
  final TauChat chat;
  final VoidCallback? updateHome;

  const GroupInfoScreen(this.chat, {super.key, this.updateHome});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final List<String> _tabs = ['Members', 'Roles'];

  int _selectedTab = 0;

  late final Future<(List<ChatMember>, RolesDTO)> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<(List<ChatMember>, RolesDTO)> _loadData() async {
    final m = await PlatformChatsService.ins.getMembers(widget.chat);
    final r = await PlatformRoleService.ins.getRoles(widget.chat);
    return (m, r);
  }

  Future<void> _showImagePreview(BuildContext context) async {
    final memoryImage =
        await ChatAvatarService.ins.loadOrFetchGroupAvatar(widget.chat);
    if (memoryImage == null) return;

    final image = Image.memory(memoryImage.bytes, fit: BoxFit.contain);

    await previewImage(context, image);
  }

  Future<void> _pickAndSetGroupAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    await ChatAvatarService.ins.setGroupAvatar(widget.chat, pickedFile.path);
    if (mounted) setState(() {});
    widget.updateHome?.call();
  }

  Future<void> _addMember(BuildContext context) async {
    final dialogs = widget.chat.client.chats.values.where(isDialog).toList();
    await moveTo(
        context,
        MembersInviteScreen(
          chats: dialogs,
          chatToInvite: widget.chat,
        ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.chat.record as GroupDTO;

    return Scaffold(
      appBar: TauAppBar.empty(),
      body: FutureBuilder<(List<ChatMember>, RolesDTO)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: TauLoading());
          }
          if (snapshot.hasError) {
            print(snapshot.error);
            print(snapshot.stackTrace);
            return const Center(
              child: Text(
                'Failed to load data.',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          final (members, roles) = snapshot.data!;

          return Column(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: () => _showImagePreview(context),
                      child: ChatAvatar(widget.chat, d: 200),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          onPressed: () => _pickAndSetGroupAvatar(context),
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                record.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              _buildTabs(),
              const SizedBox(height: 12),
              Expanded(child: _buildTabContent(record, members)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabs() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_tabs.length, (i) {
          return _buildTabButton(_tabs[i], i);
        }),
      );

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Colors.blueAccent.withAlpha(192)
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blueAccent : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(GroupDTO record, List<ChatMember> members) {
    return switch (_selectedTab) {
      0 => _buildMembersTab(record, members),
      1 => _buildRolesTab(record, members),
      _ => const Center(child: Text('Tab not implemented'))
    };
  }

  Widget _buildMembersTab(GroupDTO record, List<ChatMember> members) {
    final currentUser = widget.chat.client.user?.nickname;

    if (members.isEmpty) {
      return const Center(
        child: Text(
          'No members found.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: members.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          if (currentUser != record.owner) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: () => _addMember(context),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add member'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          );
        }
        return _buildMember(members[index - 1], record);
      },
    );
  }

  Widget _buildMember(ChatMember member, GroupDTO record) {
    final client = widget.chat.client;
    final nickname = member.nickname;

    final isOwner = nickname == record.owner;

    final List<Widget> roleChips = [];

    if (isOwner) {
      roleChips.add(_buildRoleChip('Owner', Colors.blueAccent));
    }

    for (final role in member.roles) {
      final randomColor = getRandomColor(role.id.toString());
      roleChips.add(_buildRoleChip(role.name, randomColor));
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      leading: MemberAvatar(client: client, nickname: nickname, d: 40),
      onTap: () {
        final screen = client.user?.nickname == nickname
            ? ProfileScreen(client)
            : MemberInfoScreen(client: client, nickname: nickname);
        moveTo(context, screen);
      },
      title: Text(
        nickname,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            member.status.name,
            style: TextStyle(color: member.status.color),
          ),
          const SizedBox(height: 4),
          if (roleChips.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: roleChips,
            ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRolesTab(GroupDTO record, List<ChatMember> members) {
    if (members.isEmpty) {
      return const Center(
        child: Text(
          'No roles found.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final Set<RoleDTO> uniqueRoles = {};
    bool hasOwner = false;

    for (final m in members) {
      if (m.nickname == record.owner) hasOwner = true;
      for (final role in m.roles) {
        uniqueRoles.add(role);
      }
    }

    final rolesList = uniqueRoles.toList()..sort();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: (hasOwner ? 1 : 0) + rolesList.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (hasOwner && index == 0) {
          return ListTile(
            leading: const Icon(Icons.star, color: Colors.blueAccent),
            title: const Text('Owner'),
            subtitle: const Text('Group Owner'),
          );
        }

        final roleIndex = index - (hasOwner ? 1 : 0);
        final role = rolesList[roleIndex];
        return GestureDetector(
          onLongPressStart: (details) async {
            final pos = details.globalPosition;
            await showMenu(
              context: context,
              position: RelativeRect.fromLTRB(50, pos.dy, 50, pos.dy),
              items: [
                PopupMenuItem(
                  child: const Row(children: [
                    Icon(Icons.copy),
                    SizedBox(width: 4),
                    Text("Copy ID"),
                  ]),
                  onTap: () async {
                    UUID id = role.id;
                    await Clipboard.setData(ClipboardData(text: id.toString()));
                    snackBar(context, 'Copied: $id');
                  },
                ),
              ],
            );
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: getRandomColor(role.id.toString()),
              child: Text(
                role.name.characters.firstOrNull ?? "?",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(role.name),
          ),
        );
      },
    );
  }
}
