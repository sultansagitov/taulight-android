import 'package:taulight/classes/role_dto.dart';
import 'package:taulight/classes/tau_chat.dart';
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
      var obj = result.obj;
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
    var allRoles = (map["all-roles"] as List)
        .map((r) => RoleDTO.fromMap(r))
        .toSet();

    var memberRolesIds = (map["member-roles"] as List).cast<String>().toSet();
    var memberRoles =
    allRoles.where((r) => memberRolesIds.contains(r.id)).toSet();

    var permissions = (map["permissions"] as List)
        .map((p) => Permission.fromStr(p))
        .toSet();

    return RolesDTO(allRoles, memberRoles, permissions);
  }
}