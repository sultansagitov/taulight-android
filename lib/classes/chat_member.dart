import 'package:flutter/material.dart';
import 'package:taulight/classes/nickname.dart';
import 'package:taulight/classes/role_dto.dart';
import 'package:taulight/classes/uuid.dart';

class ChatMember {
  final Nickname nickname;
  final Status status;
  final List<RoleDTO> roles;

  const ChatMember(this.nickname, this.status, this.roles);

  factory ChatMember.fromMap(List<RoleDTO> roles, map) {
    final nickname = Nickname.checked(map["nickname"]);
    final status = Status.fromString(map["status"]);
    final List? list = map["roles"];

    final roleIds = list?.map((id) => UUID.fromString(id)).toSet() ?? {};
    final matchedRoles = roles.where((r) => roleIds.contains(r.id)).toList();

    return ChatMember(nickname, status, matchedRoles);
  }
}

enum Status {
  online(Colors.green),
  offline(Colors.grey),
  hidden(Colors.blueGrey);

  final Color color;

  const Status(this.color);

  factory Status.fromString(String str) => Status.values.firstWhere(
        (s) => s.name == str.toLowerCase(),
        orElse: () => Status.hidden,
      );
}
