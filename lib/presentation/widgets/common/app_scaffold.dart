import 'package:flutter/material.dart';

import 'app_background.dart';
import 'app_top_bar.dart';

/// Shared application shell with optional top bar and safe-area body.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.showTopBar = true,
    this.showBackButton,
    this.showLogout = false,
    this.actions,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;
  final bool showTopBar;
  final bool? showBackButton;
  final bool showLogout;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final hasTopBar = showTopBar && title != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: hasTopBar
              ? AppTopBar(
                  title: title!,
                  showBackButton: showBackButton,
                  showLogout: showLogout,
                  actions: actions,
                )
              : null,
          body: SafeArea(child: body),
          floatingActionButton: floatingActionButton,
        ),
      ],
    );
  }
}
