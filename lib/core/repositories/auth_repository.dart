import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../repositories/permissions_repository.dart';

/// Authentication data access against Supabase.
class AuthRepository {
  AuthRepository({
    PermissionsRepository? permissionsRepository,
  }) : _permissionsRepository =
            permissionsRepository ?? PermissionsRepository();

  final _supabase = Supabase.instance.client;
  final PermissionsRepository _permissionsRepository;

  Future<app_user.AuthUser> login(String input, String password) async {
    final normalized = input.trim();
    if (normalized.isEmpty) {
      throw Exception('Username is required');
    }

    final response = await _supabase
        .from('users')
        .select()
        .ilike('username', '%$normalized%')
        .limit(1)
        .maybeSingle();

    if (response == null) {
      throw Exception('Your user profile was not found in the live database.');
    }

    final role = response['role'] as String? ?? 'Technician';
    final permissions = await _permissionsRepository.fetchForRole(role);

    return app_user.AuthUser(
      id: response['id'] as String,
      name: response['name'] as String? ?? '',
      username: response['username'] as String? ?? normalized,
      role: role,
      token: 'mock-token-no-auth',
      permissions: permissions,
    );
  }

  void dispose() {
    _permissionsRepository.dispose();
  }
}
