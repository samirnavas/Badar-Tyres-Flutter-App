/// An authenticated user returned by the login endpoint.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.token,
  });

  final String id;
  final String name;
  final String username;
  final String role;
  final String token;

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
