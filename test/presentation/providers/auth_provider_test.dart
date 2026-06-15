import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/core/auth/auth_constants.dart';
import 'package:iasa/core/auth/auth_user.dart';
import 'package:iasa/core/auth/session_storage.dart';
import 'package:iasa/domain/enums/user_role.dart';
import 'package:iasa/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AuthProvider> createAuthProvider([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await SessionStorage.create();
  return AuthProvider(storage);
}

void main() {
  group('AuthProvider', () {
    test('successful login authenticates warrior and persists session', () async {
      final provider = await createAuthProvider();

      final success = await provider.login(
        AuthConstants.warriorEmail,
        AuthConstants.demoPassword,
      );

      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser, const AuthUser(
        email: AuthConstants.warriorEmail,
        role: UserRole.warrior,
      ));
      expect(provider.selectedRole, UserRole.warrior);

      final storage = await SessionStorage.create();
      expect(storage.loadSession()?.email, AuthConstants.warriorEmail);
      expect(storage.loadSession()?.role, UserRole.warrior);
    });

    test('successful login authenticates moderator', () async {
      final provider = await createAuthProvider();

      final success = await provider.login(
        AuthConstants.moderatorEmail,
        AuthConstants.demoPassword,
      );

      expect(success, isTrue);
      expect(provider.currentUser?.role, UserRole.moderator);
    });

    test('failed login leaves user unauthenticated', () async {
      final provider = await createAuthProvider();

      final success = await provider.login(
        AuthConstants.warriorEmail,
        'wrong-password',
      );

      expect(success, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);

      final storage = await SessionStorage.create();
      expect(storage.loadSession(), isNull);
    });

    test('restoreSession loads persisted user', () async {
      final provider = await createAuthProvider({
        AuthConstants.prefIsLoggedIn: true,
        AuthConstants.prefEmail: AuthConstants.moderatorEmail,
        AuthConstants.prefRole: UserRole.moderator.name,
      });

      await provider.restoreSession();

      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser, const AuthUser(
        email: AuthConstants.moderatorEmail,
        role: UserRole.moderator,
      ));
    });

    test('logout clears session and user state', () async {
      final provider = await createAuthProvider();

      await provider.login(
        AuthConstants.warriorEmail,
        AuthConstants.demoPassword,
      );
      await provider.logout();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);

      final storage = await SessionStorage.create();
      expect(storage.loadSession(), isNull);
    });
  });
}
