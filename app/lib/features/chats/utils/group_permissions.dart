const _adminRoles = {'admin', 'owner'};

bool groupActionAllowed({
  required Map<String, dynamic> permissions,
  required String role,
  required String action,
}) {
  final setting = permissions[action]?.toString() ?? 'everyone';
  if (setting != 'admins') return true;
  return _adminRoles.contains(role);
}
