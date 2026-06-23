import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;

/// Authentication data access against Supabase.
class AuthRepository {
  AuthRepository();

  final _supabase = Supabase.instance.client;

  Future<app_user.AuthUser> login(String input, String password) async {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw Exception('Email or Username is required');
    }

    String emailToUse = normalized;

    // 1. If it's not an email, assume it's a username and fetch the mapped email from public.users
    if (!normalized.contains('@')) {
      final userData = await _supabase
          .from('users')
          .select('email')
          .eq('username', normalized)
          .maybeSingle();

      if (userData == null) {
        throw Exception('Invalid username or password');
      }
      emailToUse = userData['email'] as String;
    }

    // 2. Authenticate strictly with Supabase Auth using the resolved email
    final response = await _supabase.auth.signInWithPassword(
      email: emailToUse,
      password: password,
    );
    
    final user = response.user;
    final session = response.session;
    
    if (user == null || session == null) {
      throw Exception('Login failed: user or session is null');
    }

    // 3. Fetch the public profile using the strict Foreign Key (Auth UUID)
    final profile = await _supabase
        .from('users')
        .select('role, name, username')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      await _supabase.auth.signOut();
      throw Exception('Your user profile was not found. Please contact an admin to link your account.');
    }

    return app_user.AuthUser(
      id: user.id,
      name: profile['name'] as String? ?? '',
      username: profile['username'] as String? ?? normalized,
      role: profile['role'] as String? ?? 'technician',
      token: session.accessToken,
    );
  }

  void dispose() {}
}
