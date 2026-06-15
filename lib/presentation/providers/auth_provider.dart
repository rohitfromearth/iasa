import 'package:flutter/foundation.dart';

import '../../core/auth/auth_constants.dart';
import '../../core/auth/auth_user.dart';
import '../../core/auth/session_storage.dart';
import '../../domain/enums/user_role.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._sessionStorage);

  final SessionStorage _sessionStorage;

  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  UserRole? get selectedRole => _currentUser?.role;

  bool get hasRole => _currentUser != null;

  Future<bool> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final role = AuthConstants.roleForEmail(normalizedEmail);

    if (role == null || !AuthConstants.isValidPassword(password)) {
      return false;
    }

    final user = AuthUser(email: normalizedEmail, role: role);
    await _sessionStorage.saveSession(user);
    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    if (_currentUser == null) {
      return;
    }
    await _sessionStorage.clearSession();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    _currentUser = _sessionStorage.loadSession();
    notifyListeners();
  }

  /// Retained for backward compatibility with [RoleSelectionScreen].
  void selectRole(UserRole role) {
    final user = AuthUser(email: 'legacy@iasa.com', role: role);
    if (_currentUser == user) {
      return;
    }
    _currentUser = user;
    notifyListeners();
  }

  /// Retained for backward compatibility with [RoleSelectionScreen].
  void clearRole() {
    if (_currentUser == null) {
      return;
    }
    _currentUser = null;
    notifyListeners();
  }
}
