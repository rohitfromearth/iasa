import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_constants.dart';
import '../../core/constants/app_constants.dart';
import '../navigation/app_navigator.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_logo.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/password_text_field.dart';
import '../widgets/common/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Enter a valid email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await context.read<AuthProvider>().login(
          _emailController.text,
          _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      final role = context.read<AuthProvider>().currentUser!.role;
      AppNavigator.openHome(context, role);
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = 'Invalid email or password';
    });
  }

  void _applyDemoCredentials(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      showTopBar: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AppLogo(height: 140)),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          AppConstants.appName,
                          style: AppTypography.title.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Sign in to continue',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (_errorMessage != null) ...[
                          _LoginErrorBanner(message: _errorMessage!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextField(
                                label: 'Email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                autofillHints: const [AutofillHints.email],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              PasswordTextField(
                                label: 'Password',
                                controller: _passwordController,
                                textInputAction: TextInputAction.done,
                                enabled: !_isLoading,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _login(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              PrimaryButton(
                                label: 'Sign In',
                                onPressed: _login,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _DemoCredentialsSection(
                          onSelect: _applyDemoCredentials,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorRedLight,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.errorRed,
            size: AppSpacing.lg,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoCredentialsSection extends StatelessWidget {
  const _DemoCredentialsSection({
    required this.onSelect,
  });

  final void Function(String email, String password) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Demo Credentials',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DemoCredentialTile(
            roleLabel: 'Warrior',
            email: AuthConstants.warriorEmail,
            password: AuthConstants.demoPassword,
            onTap: onSelect,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DemoCredentialTile(
            roleLabel: 'Moderator',
            email: AuthConstants.moderatorEmail,
            password: AuthConstants.demoPassword,
            onTap: onSelect,
          ),
        ],
      ),
    );
  }
}

class _DemoCredentialTile extends StatelessWidget {
  const _DemoCredentialTile({
    required this.roleLabel,
    required this.email,
    required this.password,
    required this.onTap,
  });

  final String roleLabel;
  final String email;
  final String password;
  final void Function(String email, String password) onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(email, password),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                roleLabel,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(email, style: AppTypography.small),
              Text(password, style: AppTypography.small),
            ],
          ),
        ),
      ),
    );
  }
}
