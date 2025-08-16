import 'package:taulight/enums/permission.dart';

class RoleDTO {
  final String id;
  final String name;
  final List<Permission> permissions;

  const RoleDTO(this.id, this.name, this.permissions);

  factory RoleDTO.fromMap(map) {
    List<String> l = List<String>.from(map["permissions"]);
    var result = l.map((e) => Permission.fromStr(e)).toList();
    return RoleDTO(map["id"], map["name"], result);
  }
}
