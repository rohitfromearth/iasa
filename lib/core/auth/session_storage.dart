import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enums/user_role.dart';
import 'auth_constants.dart';
import 'auth_user.dart';

class SessionStorage {
  SessionStorage(this._preferences);

  final SharedPreferences _preferences;

  static Future<SessionStorage> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SessionStorage(preferences);
  }

  Future<void> saveSession(AuthUser user) async {
    await _preferences.setBool(AuthConstants.prefIsLoggedIn, true);
    await _preferences.setString(AuthConstants.prefEmail, user.email);
    await _preferences.setString(AuthConstants.prefRole, user.role.name);
  }

  Future<void> clearSession() async {
    await _preferences.remove(AuthConstants.prefIsLoggedIn);
    await _preferences.remove(AuthConstants.prefEmail);
    await _preferences.remove(AuthConstants.prefRole);
  }

  AuthUser? loadSession() {
    final isLoggedIn = _preferences.getBool(AuthConstants.prefIsLoggedIn) ?? false;
    if (!isLoggedIn) {
      return null;
    }

    final email = _preferences.getString(AuthConstants.prefEmail);
    final roleName = _preferences.getString(AuthConstants.prefRole);
    if (email == null || roleName == null) {
      return null;
    }

    try {
      final role = UserRole.values.byName(roleName);
      return AuthUser(email: email, role: role);
    } catch (_) {
      return null;
    }
  }
}
