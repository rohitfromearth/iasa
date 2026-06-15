import 'package:flutter/material.dart';

import '../../navigation/app_navigator.dart';

/// App bar action that signs out and returns to the login screen.
class LogoutAction extends StatelessWidget {
  const LogoutAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Logout',
      icon: const Icon(Icons.logout_rounded),
      onPressed: () => AppNavigator.logout(context),
    );
  }
}
