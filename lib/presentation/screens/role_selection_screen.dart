import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/ui_state.dart';
import '../../domain/enums/user_role.dart';
import '../navigation/app_navigator.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/ui_state_view.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  _RolePhase _phase = _RolePhase.success;

  Future<void> _selectRole(UserRole role) async {
    setState(() => _phase = _RolePhase.loading);
    context.read<AuthProvider>().selectRole(role);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) {
      return;
    }
    AppNavigator.openRoleHome(context, role);
    setState(() => _phase = _RolePhase.success);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Select Role',
      body: UiStateView<void>(
        state: _phase.uiState,
        emptyMessage: 'No roles are configured for this device',
        successBuilder: (_) => _RoleSelectionBody(onSelectRole: _selectRole),
        initialBuilder: () => _RoleSelectionBody(onSelectRole: _selectRole),
        onRetry: () => setState(() => _phase = _RolePhase.success),
      ),
    );
  }
}

enum _RolePhase { loading, empty, error, success }

extension _RolePhaseUi on _RolePhase {
  UiState<void> get uiState => switch (this) {
        _RolePhase.loading => const UiLoading(),
        _RolePhase.empty => const UiEmpty(message: 'No roles are configured'),
        _RolePhase.error => const UiError('Unable to start session'),
        _RolePhase.success => const UiSuccess(null),
      };
}

class _RoleSelectionBody extends StatelessWidget {
  const _RoleSelectionBody({required this.onSelectRole});

  final Future<void> Function(UserRole role) onSelectRole;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Healthcare Workflow',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to use the app.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => onSelectRole(UserRole.warrior),
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Warrior'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => onSelectRole(UserRole.moderator),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Moderator'),
          ),
        ],
      ),
    );
  }
}
