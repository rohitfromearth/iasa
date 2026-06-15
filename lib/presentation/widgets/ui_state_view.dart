import 'package:flutter/material.dart';

import '../../core/state/ui_state.dart';

class UiStateView<T> extends StatelessWidget {
  const UiStateView({
    super.key,
    required this.state,
    required this.successBuilder,
    this.onRetry,
    this.loadingMessage = 'Loading...',
    this.emptyMessage = 'Nothing to show yet',
    this.initialBuilder,
  });

  final UiState<T> state;
  final Widget Function(T data) successBuilder;
  final VoidCallback? onRetry;
  final String loadingMessage;
  final String emptyMessage;
  final Widget Function()? initialBuilder;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      UiInitial<T>() =>
        initialBuilder?.call() ?? _StatusBody(message: emptyMessage, icon: Icons.inbox_outlined),
      UiLoading<T>() => _StatusBody(
          message: loadingMessage,
          icon: Icons.hourglass_top,
          showProgress: true,
        ),
      UiEmpty<T>(message: final message) => _StatusBody(
          message: message ?? emptyMessage,
          icon: Icons.inbox_outlined,
        ),
      UiError<T>(message: final message) => _StatusBody(
          message: message,
          icon: Icons.error_outline,
          action: onRetry == null
              ? null
              : FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      UiSuccess<T>(data: final data) => successBuilder(data),
    };
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.message,
    required this.icon,
    this.showProgress = false,
    this.action,
  });

  final String message;
  final IconData icon;
  final bool showProgress;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: CircularProgressIndicator(),
              )
            else
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
