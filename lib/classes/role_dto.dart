import 'package:taulight/classes/uuid.dart';
import 'package:taulight/enums/permission.dart';

class RoleDTO {
  final UUID id;
  final String name;
  final List<Permission> permissions;

  const RoleDTO(this.id, this.name, this.permissions);

  factory RoleDTO.fromMap(map) => RoleDTO(
        UUID.fromString(map["id"]),
        map["name"]!,
        List<String>.from(map["permissions"])
            .map((e) => Permission.fromStr(e))
            .toList(),
      );
}
