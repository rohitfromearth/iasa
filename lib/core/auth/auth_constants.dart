import '../../domain/enums/user_role.dart';

/// Dummy offline credentials for assessment demonstration only.
abstract final class AuthConstants {
  static const String prefIsLoggedIn = 'isLoggedIn';
  static const String prefEmail = 'email';
  static const String prefRole = 'role';

  static const String warriorEmail = 'warrior@iasa.com';
  static const String moderatorEmail = 'moderator@iasa.com';
  static const String demoPassword = 'password123';

  static const Map<String, UserRole> credentials = {
    warriorEmail: UserRole.warrior,
    moderatorEmail: UserRole.moderator,
  };

  static UserRole? roleForEmail(String email) => credentials[email.trim().toLowerCase()];

  static bool isValidPassword(String password) => password == demoPassword;
}
