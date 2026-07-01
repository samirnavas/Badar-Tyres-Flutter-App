import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/role_permissions.dart';

/// Reads role-based route permissions from Supabase.
class PermissionsRepository {
  PermissionsRepository();

  final _supabase = Supabase.instance.client;

  Future<RolePermissions> fetchForRole(String role) async {
    final normalizedRole = role.trim();
    if (normalizedRole.isEmpty) return RolePermissions.empty;

    final exact = await _supabase
        .from('permissions')
        .select('routes')
        .eq('role', normalizedRole)
        .maybeSingle();

    if (exact != null) {
      return RolePermissions.fromDbValue(exact['routes']);
    }

    final rows = await _supabase.from('permissions').select('role, routes');
    for (final row in rows) {
      final dbRole = row['role'] as String? ?? '';
      if (dbRole.toLowerCase() == normalizedRole.toLowerCase()) {
        return RolePermissions.fromDbValue(row['routes']);
      }
    }

    return RolePermissions.empty;
  }

  void dispose() {}
}
