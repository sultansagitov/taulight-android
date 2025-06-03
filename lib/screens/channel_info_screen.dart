import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/chat_member.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/screens/members_invite_screen.dart';
import 'package:taulight/services/avatar_service.dart';
import 'package:taulight/utils.dart';
import 'package:taulight/widget_utils.dart';
import 'package:taulight/widgets/chat_avatar.dart';

class ChannelInfoScreen extends StatefulWidget {
  final TauChat chat;
  final VoidCallback? updateHome;

  const ChannelInfoScreen(this.chat, {super.key, this.updateHome});

  @override
  State<ChannelInfoScreen> createState() => _ChannelInfoScreenState();
}

class _ChannelInfoScreenState extends State<ChannelInfoScreen> {
  List<ChatMember> _members = [];
  bool _loadingError = false;
  bool _isLoading = true;

  final List<String> _tabs = ['Members', 'Roles'];

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      if (widget.chat.client.connected) {
        final fetchedMembers = await widget.chat.getMembers();
        if (mounted) {
          setState(() {
            _members = fetchedMembers;
            _loadingError = false;
            _isLoading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);

      if (mounted) {
        setState(() {
          _loadingError = true;
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndSetChannelAvatar(
      BuildContext context, TauChat chat) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    await AvatarService.ins.setChannelAvatar(chat, pickedFile.path);
    if (mounted) setState(() {});
    widget.updateHome?.call();
  }

  Future<void> _showAddMemberDialog(BuildContext context) async {
    var dialogs = widget.chat.client.chats.values.where(isDialog).toList();
    var screen = MembersInviteScreen(chats: dialogs, chatToInvite: widget.chat);
    await moveTo(context, screen);
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.chat.record as ChannelDTO;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          record.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => _pickAndSetChannelAvatar(context, widget.chat),
              child: ChatAvatar(widget.chat, d: 80),
            ),
          ),
          const SizedBox(height: 16),
          _buildTabs(),
          const SizedBox(height: 12),
          Expanded(
            child: _buildTabContent(record),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_tabs.length, (index) {
        return _buildTabButton(_tabs[index], index);
      }),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
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

  Widget _buildTabContent(ChannelDTO record) {
    switch (_selectedTab) {
      case 0:
        return _buildMembersTab(record);
      case 1:
        return _buildRolesTab(record);
      case 2:
        return _buildInfoTab(record);
      case 3:
        return _buildSettingsTab(record);
      default:
        return Center(child: Text('Tab not implemented'));
    }
  }

  Widget _buildMembersTab(ChannelDTO record) {
    final currentUser = widget.chat.client.user?.nickname;

    if (_loadingError) {
      return const Center(
        child: Text(
          'Failed to load members.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_members.isEmpty) {
      return const Center(
        child: Text(
          'No members found.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: _members.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          if (currentUser != record.owner) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: () => _showAddMemberDialog(context),
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

        return _buildMember(_members[index - 1], record);
      },
    );
  }

  Widget _buildMember(ChatMember member, ChannelDTO record) {
    final isOwner = member.nickname == record.owner;

    final List<Widget> roleChips = [];

    if (isOwner) {
      roleChips.add(_buildRoleChip('Owner', Colors.blueAccent));
    }

    for (final role in member.roles) {
      roleChips.add(_buildRoleChip(role.name, getRandomColor(role.id)));
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      leading: DialogInitials(
        initials: getInitials(member.nickname),
        bgColor: getRandomColor(member.nickname),
        d: 40,
      ),
      title: Text(
        member.nickname,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(member.status.name),
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

  Widget _buildRolesTab(ChannelDTO record) {
    if (_loadingError) {
      return const Center(
        child: Text(
          'Failed to load members.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_members.isEmpty) {
      return const Center(
        child: Text(
          'No roles found.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final Set<String> uniqueRoles = {};
    bool hasOwner = false;

    for (var member in _members) {
      if (member.nickname == record.owner) {
        hasOwner = true;
      }
      for (var role in member.roles) {
        uniqueRoles.add(role.name);
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
            leading: Icon(Icons.star, color: Colors.blueAccent),
            title: const Text('Owner'),
            subtitle: const Text('Channel Owner'),
          );
        }

        final roleIndex = index - (hasOwner ? 1 : 0);
        final roleName = rolesList[roleIndex];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: getRandomColor(roleName),
            child: Text(
              roleName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(roleName),
        );
      },
    );
  }

  Widget _buildInfoTab(ChannelDTO record) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Channel ID: ${record.id}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSettingsTab(ChannelDTO record) {
    return Center(
      child: Text(
        'Settings Tab - Coming Soon',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
      ),
    );
  }
}
