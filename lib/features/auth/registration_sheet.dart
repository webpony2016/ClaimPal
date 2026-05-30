import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/privacy_badge.dart';
import '../../data/models/lawsuit.dart';
import '../account/account_provider.dart';

/// Presents the registration half-sheet that gates the filing flow for guests.
///
/// On a successful (mock) registration the sheet closes and navigation
/// proceeds to `/filing/${lawsuit.id}`.
Future<void> showRegistrationSheet(
  BuildContext context,
  WidgetRef ref,
  Lawsuit lawsuit,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AppBottomSheet(
      child: _RegistrationSheetBody(ref: ref, lawsuit: lawsuit),
    ),
  );
}

class _RegistrationSheetBody extends StatefulWidget {
  const _RegistrationSheetBody({required this.ref, required this.lawsuit});

  final WidgetRef ref;
  final Lawsuit lawsuit;

  @override
  State<_RegistrationSheetBody> createState() => _RegistrationSheetBodyState();
}

class _RegistrationSheetBodyState extends State<_RegistrationSheetBody> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Mock registration: guest -> registered (stays on starter tier).
    widget.ref.read(accountProvider.notifier).register();

    final id = widget.lawsuit.id;
    Navigator.of(context).pop();
    // The sheet's context is unmounted after pop; use the parent context only
    // while still mounted.
    if (context.mounted) {
      context.go('/filing/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Create an account to file', style: AppTextStyles.headlineMd),
          const SizedBox(height: 8),
          Text(
            'Filing a claim requires a free account so we can save your '
            'progress and notify you about your payout.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Email address',
                  style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'name@example.com',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Continue'),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Expanded(child: Divider(color: AppColors.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.outlineVariant)),
            ],
          ),
          const SizedBox(height: 16),
          _SocialButton(
            icon: Icons.apple,
            label: 'Continue with Apple',
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          _SocialButton(
            icon: Icons.g_mobiledata,
            label: 'Continue with Google',
            onPressed: _submit,
          ),
          const SizedBox(height: 24),
          const Center(child: PrivacyBadge()),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: AppColors.outlineVariant),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
