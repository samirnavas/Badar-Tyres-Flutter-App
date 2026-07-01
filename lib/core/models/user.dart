import 'role_permissions.dart';

/// An authenticated user returned by the login endpoint.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.token,
    this.permissions = RolePermissions.empty,
  });

  final String id;
  final String name;
  final String username;
  final String role;
  final String token;
  final RolePermissions permissions;

  bool get isAdminRole =>
      role.toLowerCase() == 'admin' || permissions.isAdmin;

  bool get isTechnician => role.toLowerCase() == 'technician';

  bool canAccess(String route) => permissions.canAccess(route);

  AuthUser copyWith({
    String? id,
    String? name,
    String? username,
    String? role,
    String? token,
    RolePermissions? permissions,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      role: role ?? this.role,
      token: token ?? this.token,
      permissions: permissions ?? this.permissions,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};
    return AuthUser(
      id: user['id'] as String? ?? '',
      name: user['name'] as String? ?? '',
      username: user['username'] as String? ?? '',
      role: user['role'] as String? ?? '',
      token: json['token'] as String? ?? '',
    );
  }
}
