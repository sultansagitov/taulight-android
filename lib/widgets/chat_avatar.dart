import 'package:flutter/material.dart';
import 'package:taulight/chat_filters.dart';
import 'package:taulight/classes/chat_dto.dart';
import 'package:taulight/classes/client.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/services/avatar_service.dart';
import 'package:taulight/services/profile_avatar_service.dart';
import 'package:taulight/utils.dart';

class ChatAvatar extends StatefulWidget {
  final TauChat chat;
  final int d;

  ChatAvatar(this.chat, {required this.d})
      : super(key: ValueKey(chat.avatarID));

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
      return isLoading || avatarImage == null
          ? GroupInitials(
              initials: initials,
              bgColor: bgColor,
              d: widget.d,
            )
          : GroupAvatar(
              avatarImage: avatarImage!,
              d: widget.d,
            );
    } else if (isDialog(widget.chat)) {
      var dialog = widget.chat.record as DialogDTO;
      return !dialog.isMonolog
          ? isLoading || avatarImage == null
              ? DialogInitials(
                  initials: initials,
                  bgColor: bgColor,
                  d: widget.d,
                )
              : DialogAvatar(
                  avatarImage: avatarImage!,
                  d: widget.d,
                )
          : MonologAvatar(
              d: widget.d,
              bgColor: bgColor,
            );
    }

    return SizedBox(width: widget.d.toDouble(), height: widget.d.toDouble());
  }
}

class GroupInitials extends StatelessWidget {
  final String initials;
  final Color bgColor;
  final int d;
  const GroupInitials({
    required this.initials,
    required this.bgColor,
    required this.d,
    super.key,
  });

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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: d.toDouble() * 0.4,
          ),
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
  const DialogInitials({
    required this.initials,
    required this.bgColor,
    required this.d,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(d.toDouble() * 0.2),
      child: Container(
        width: d.toDouble(),
        height: d.toDouble(),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [bgColor, bgColor.withAlpha(200)]),
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: d.toDouble() * 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class DialogAvatar extends StatelessWidget {
  final MemoryImage avatarImage;
  final int d;
  const DialogAvatar({
    required this.avatarImage,
    required this.d,
    super.key,
  });

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

class MonologAvatar extends StatelessWidget {
  final int d;
  final Color bgColor;

  const MonologAvatar({
    super.key,
    required this.d,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: d.toDouble(),
        height: d.toDouble(),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            bgColor,
            bgColor.withAlpha(200),
          ]),
        ),
        child: Center(
            child: Icon(
          Icons.lock,
          color: Colors.white,
          size: 24,
        )),
      ),
    );
  }
}

class MyAvatar extends StatelessWidget {
  final Client client;
  final int d;

  const MyAvatar({
    super.key,
    required this.client,
    required this.d,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ProfileAvatarService.ins.getAvatar(client),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error);
          print(snapshot.stackTrace);
        }

        var avatarBytes = snapshot.data?.bytes;

        if (avatarBytes == null) {
          var initials = getInitials(client.user!.nickname);
          var bg = getRandomColor(client.user!.nickname);
          return DialogInitials(initials: initials, bgColor: bg, d: d);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(d.toDouble() * 0.2),
          child: Image.memory(
            avatarBytes,
            width: d.toDouble(),
            height: d.toDouble(),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
