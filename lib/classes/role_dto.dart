class RoleDTO {
  final String id;
  final String name;

  const RoleDTO(this.id, this.name);

  factory RoleDTO.fromMap(map) => RoleDTO(map["id"], map["name"]);
}
