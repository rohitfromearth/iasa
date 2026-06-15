import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'presentation/navigation/app_navigator.dart';
import 'presentation/navigation/routes.dart';
import 'presentation/theme/app_theme.dart';

/// Root application widget.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppNavigator.onGenerateRoute,
    );
  }
}
