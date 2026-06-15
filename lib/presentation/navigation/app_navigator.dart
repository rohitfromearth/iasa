import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/enums/user_role.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/moderator/moderator_queue_screen.dart';
import '../screens/moderator/update_status_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/warrior/case_detail_screen.dart';
import '../screens/warrior/case_list_screen.dart';
import '../screens/warrior/submit_question_screen.dart';
import 'routes.dart';

abstract final class AppNavigator {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case AppRoutes.warriorCaseList:
        return MaterialPageRoute(builder: (_) => const CaseListScreen());
      case AppRoutes.warriorCaseDetail:
        final caseId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => CaseDetailScreen(caseId: caseId ?? ''),
        );
      case AppRoutes.warriorSubmitQuestion:
        final caseId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => SubmitQuestionScreen(caseId: caseId),
        );
      case AppRoutes.moderatorQueue:
        return MaterialPageRoute(builder: (_) => const ModeratorQueueScreen());
      case AppRoutes.moderatorUpdateStatus:
        final caseId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => UpdateStatusScreen(caseId: caseId ?? ''),
        );
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }

  static void openLogin(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  static void openHome(BuildContext context, UserRole role) {
    final route = switch (role) {
      UserRole.warrior => AppRoutes.warriorCaseList,
      UserRole.moderator => AppRoutes.moderatorQueue,
    };
    Navigator.of(context).pushReplacementNamed(route);
  }

  static Future<void> logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  static void openCaseDetail(BuildContext context, String caseId) {
    Navigator.of(context).pushNamed(
      AppRoutes.warriorCaseDetail,
      arguments: caseId,
    );
  }

  static void openSubmitQuestion(BuildContext context, {String? caseId}) {
    Navigator.of(context).pushNamed(
      AppRoutes.warriorSubmitQuestion,
      arguments: caseId,
    );
  }

  static void openUpdateStatus(BuildContext context, String caseId) {
    Navigator.of(context).pushNamed(
      AppRoutes.moderatorUpdateStatus,
      arguments: caseId,
    );
  }

  /// Retained for backward compatibility with [RoleSelectionScreen].
  static void openRoleHome(BuildContext context, UserRole role) {
    openHome(context, role);
  }

  /// Retained for backward compatibility with [RoleSelectionScreen].
  static void backToRoleSelection(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.roleSelection,
      (route) => false,
    );
  }
}
