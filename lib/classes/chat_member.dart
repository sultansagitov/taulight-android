import 'package:taulight/classes/role_dto.dart';

class ChatMember {
  final String nickname;
  final Status status;
  final List<RoleDTO> roles;

  const ChatMember(this.nickname, this.status, this.roles);

  factory ChatMember.fromMap(List<RoleDTO> roles, map) {
    var rolesIds = map["roles"] as List<String>?;
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
  online,
  offline,
  hidden;

  factory Status.fromString(String s) {
    for (Status status in Status.values) {
      if (status.name == s.toLowerCase()) {
        return status;
      }
    }

    return Status.hidden;
  }
}
