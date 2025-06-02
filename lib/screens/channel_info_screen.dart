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
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => _pickAndSetChannelAvatar(context, widget.chat),
                child: ChatAvatar(widget.chat, d: 80),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Members',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_members.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingError)
              const Text(
                'Failed to load members.',
                style: TextStyle(color: Colors.red),
              ),
            if (!_loadingError && _members.isEmpty)
              const Text(
                'No members found.',
                style: TextStyle(color: Colors.grey),
              ),
            if (_members.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: _members.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isOwner =
                          widget.chat.client.user?.nickname == record.owner;
                      return isOwner
                          ? TextButton.icon(
                              onPressed: () => _showAddMemberDialog(context),
                              icon: const Icon(Icons.person_add_outlined),
                              label: const Text('Add member'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blueAccent,
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            )
                          : const SizedBox.shrink();
                    }

                    final member = _members[index - 1];
                    final isOwner = member.nickname == record.owner;

                    return ListTile(
                      leading: DialogInitials(
                        initials: getInitials(member.nickname),
                        bgColor: getRandomColor(member.nickname),
                        d: 40,
                      ),
                      title: Text(
                        member.nickname,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        member.status.name,
                      ),
                      trailing: Text(
                        isOwner ? 'Owner' : 'Member',
                        style: TextStyle(
                          color: isOwner ? Colors.blueAccent : Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMemberDialog(BuildContext context) async {
    var dialogs = widget.chat.client.chats.values.where(isDialog).toList();
    await moveTo(context,
        MembersInviteScreen(chats: dialogs, chatToInvite: widget.chat));
  }
}
