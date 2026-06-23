import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

/// Persists the signed-in session so a "remembered" user is kept logged in
/// across app launches, and the login form can pre-fill the last username.
///
/// Security note: the password is never stored. When "Remember me" is enabled
/// we keep the session token + lightweight user details returned by the login
/// endpoint; otherwise only the username is retained for convenience.
class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  static const _kRemember = 'auth_remember_me';
  static const _kUsername = 'auth_username';
  static const _kId = 'auth_user_id';
  static const _kName = 'auth_user_name';
  static const _kRole = 'auth_user_role';
  static const _kToken = 'auth_token';

  /// Whether the last sign-in opted into being remembered.
  Future<bool> get rememberMe async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRemember) ?? false;
  }

  /// The last username used to sign in, kept for pre-filling the form even
  /// after an explicit logout.
  Future<String?> get savedUsername async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUsername);
  }

  /// Stores the result of a successful login. The full session is persisted
  /// only when [rememberMe] is true; otherwise we drop any prior session but
  /// still remember the username.
  Future<void> save(AuthUser user, {required bool rememberMe}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRemember, rememberMe);
    await prefs.setString(_kUsername, user.username);
    if (rememberMe) {
      await prefs.setString(_kId, user.id);
      await prefs.setString(_kName, user.name);
      await prefs.setString(_kRole, user.role);
      await prefs.setString(_kToken, user.token);
    } else {
      await _clearSession(prefs);
    }
  }

  /// The remembered user, or null if "remember me" wasn't active at last login.
  /// Used at startup to skip the login screen.
  Future<AuthUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kRemember) ?? false)) return null;
    final token = prefs.getString(_kToken);
    final username = prefs.getString(_kUsername);
    if (token == null || username == null) return null;
    return AuthUser(
      id: prefs.getString(_kId) ?? '',
      name: prefs.getString(_kName) ?? '',
      username: username,
      role: prefs.getString(_kRole) ?? '',
      token: token,
    );
  }

  /// Ends the active session. The saved username is kept so the next login can
  /// pre-fill it, but auto-login is disabled until the user opts in again.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearSession(prefs);
    await prefs.setBool(_kRemember, false);
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(_kId);
    await prefs.remove(_kName);
    await prefs.remove(_kRole);
    await prefs.remove(_kToken);
  }
}
