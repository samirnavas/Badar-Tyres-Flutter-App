import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;

/// Authentication data access against Supabase.
class AuthRepository {
  AuthRepository();

  final _supabase = Supabase.instance.client;

  Future<app_user.AuthUser> login(String input, String password) async {
    final normalized = input.trim();
    if (normalized.isEmpty) {
      throw Exception('Username is required');
    }

    // Query the live database for a matching user by name or username
    final response = await _supabase
        .from('users')
        .select()
        .ilike('username', '%$normalized%')
        .limit(1)
        .maybeSingle();

    if (response == null) {
      throw Exception('Your user profile was not found in the live database.');
    }

    // Map the response to the AuthUser model using the real UUID from Supabase
    return app_user.AuthUser(
      id: response['id'] as String,
      name: response['name'] as String? ?? '',
      username: response['username'] as String? ?? normalized,
      role: response['role'] as String? ?? 'technician',
      token: 'mock-token-no-auth',
    );
  }

  void dispose() {}
}
