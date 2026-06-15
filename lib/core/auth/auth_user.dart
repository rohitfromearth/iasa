import '../../domain/enums/user_role.dart';

class AuthUser {
  const AuthUser({
    required this.email,
    required this.role,
  });

  final String email;
  final UserRole role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => Object.hash(email, role);
}
