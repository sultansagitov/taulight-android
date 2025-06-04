import 'package:flutter/material.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/avatar_service.dart';
import 'package:taulight/utils.dart';

class ChatAvatar extends StatefulWidget {
  final TauChat chat;
  final int d;

  const ChatAvatar(this.chat, {required this.d, super.key});

  @override
  State<ChatAvatar> createState() => _ChatAvatarState();
}

class _ChatAvatarState extends State<ChatAvatar> {
  MemoryImage? avatarImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    MemoryImage? image;
    if (isGroup(widget.chat)) {
      image = await AvatarService.ins.loadOrFetchGroupAvatar(widget.chat);
    } else if (isDialog(widget.chat)) {
      image = await AvatarService.ins.loadOrFetchDialogAvatar(widget.chat);
    }

    if (mounted) {
      setState(() {
        avatarImage = image;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.chat.record.getTitle();
    final initials = getInitials(title);
    final bgColor = getRandomColor(title);

    if (isGroup(widget.chat)) {
      if (isLoading || avatarImage == null) {
        return GroupInitials(
            initials: initials, bgColor: bgColor, d: widget.d);
      }
      return GroupAvatar(avatarImage: avatarImage!, d: widget.d);
    } else if (isDialog(widget.chat)) {
      if (isLoading || avatarImage == null) {
        return DialogInitials(
            initials: initials, bgColor: bgColor, d: widget.d);
      }
      return DialogAvatar(avatarImage: avatarImage!, d: widget.d);
    }

    return SizedBox(width: widget.d.toDouble(), height: widget.d.toDouble());
  }
}

class GroupInitials extends StatelessWidget {
  final String initials;
  final Color bgColor;
  final int d;
  const GroupInitials(
      {required this.initials,
      required this.bgColor,
      required this.d,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: d.toDouble(),
      height: d.toDouble(),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [bgColor, bgColor.withAlpha(200)]),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}

class GroupAvatar extends StatelessWidget {
  final MemoryImage avatarImage;
  final int d;
  const GroupAvatar({required this.avatarImage, required this.d, super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: d / 2,
      backgroundImage: avatarImage,
      backgroundColor: Colors.grey,
    );
  }
}

class DialogInitials extends StatelessWidget {
  final String initials;
  final Color bgColor;
  final int d;
  const DialogInitials(
      {required this.initials,
      required this.bgColor,
      required this.d,
      super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: d.toDouble(),
        height: d.toDouble(),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [bgColor, bgColor.withAlpha(200)]),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }
}

class DialogAvatar extends StatelessWidget {
  final MemoryImage avatarImage;
  final int d;
  const DialogAvatar({required this.avatarImage, required this.d, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: d.toDouble(),
        height: d.toDouble(),
        color: Colors.grey,
        child: Image.memory(
          avatarImage.bytes,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
