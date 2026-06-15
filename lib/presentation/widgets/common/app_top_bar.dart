import 'package:flutter/material.dart';

import 'logout_action.dart';

/// Material 3 app bar with title, optional back navigation, logout, and actions.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.showBackButton,
    this.showLogout = false,
    this.actions,
  });

  final String title;
  final bool? showBackButton;
  final bool showLogout;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBackButton ?? canPop;

    final barActions = <Widget>[
      ...?actions,
      if (showLogout) const LogoutAction(),
    ];

    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: shouldShowBack,
      actions: barActions.isEmpty ? null : barActions,
    );
  }
}
