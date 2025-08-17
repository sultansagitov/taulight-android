import 'package:taulight/classes/role_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
import 'package:taulight/classes/uuid.dart';
import 'package:taulight/enums/permission.dart';
import 'package:taulight/exceptions.dart';
import 'package:taulight/services/platform/platform_service.dart';

class PlatformRoleService {
  static final _instance = PlatformRoleService._internal();
  static PlatformRoleService get ins => _instance;
  PlatformRoleService._internal();

  Future<RolesDTO> getRoles(TauChat chat) async {
    Result result = await PlatformService.ins.chain(
      "RoleClientChain.getRoles",
      client: chat.client,
      params: [chat.record.id],
    );

    if (result is ExceptionResult) {
      if (result.name == "NotFoundException") {
        throw ChatNotFoundException(chat.client);
      }
      throw result.getCause(chat.client);
    }

    if (result is SuccessResult) {
      final obj = result.obj;
      if (obj is Map) {
        return RolesDTO.fromMap(obj);
      }
    }

    throw IncorrectFormatChannelException();
  }
}

class RolesDTO {
  final Set<RoleDTO> allRoles;
  final Set<RoleDTO> memberRoles;
  final Set<Permission> permissions;

  RolesDTO(this.allRoles, this.memberRoles, this.permissions);

  factory RolesDTO.fromMap(map) {
    final rawAll = map["all-roles"] as List;
    final rawMember = map["member-roles"] as List;
    final rawPerm = map["permissions"] as List;

    final allRoles = rawAll.map((r) => RoleDTO.fromMap(r)).toSet();

    final memberId = rawMember.map((id) => UUID.fromString(id)).toSet();
    final memberRoles = allRoles.where((r) => memberId.contains(r.id)).toSet();

    final permissions = rawPerm.map((p) => Permission.fromStr(p)).toSet();

    return RolesDTO(allRoles, memberRoles, permissions);
  }
}
