import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Password field with visibility toggle.
class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.textInputAction,
    this.validator,
    this.enabled = true,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool enabled;
  final List<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      enabled: widget.enabled,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: AppSpacing.lg,
          ),
          onPressed: widget.enabled
              ? () => setState(() => _obscureText = !_obscureText)
              : null,
          tooltip: _obscureText ? 'Show password' : 'Hide password',
        ),
      ),
    );
  }
}
