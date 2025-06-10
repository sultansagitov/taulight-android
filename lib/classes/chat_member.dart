import 'package:flutter/material.dart';
import 'package:taulight/classes/role_dto.dart';

class ChatMember {
  final String nickname;
  final Status status;
  final List<RoleDTO> roles;

  const ChatMember(this.nickname, this.status, this.roles);

  factory ChatMember.fromMap(List<RoleDTO> roles, map) {
    var rolesIds =
        map["roles"] != null ? List<String>.from(map["roles"]) : null;
    var result = rolesIds != null
        ? roles.where((r) => rolesIds.contains(r.id)).toList()
        : <RoleDTO>[];
    return ChatMember(
      map["nickname"],
      Status.fromString(map["status"]),
      result,
    );
  }
}

enum Status {
  online(Colors.green),
  offline(Colors.grey),
  hidden(Colors.blueGrey);

  final Color color;

  const Status(this.color);

  factory Status.fromString(String s) {
    for (Status status in Status.values) {
      if (status.name == s.toLowerCase()) {
        return status;
      }
    }
    return Status.hidden;
  }
}