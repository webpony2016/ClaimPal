import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/user_account.dart';
import '../account/account_provider.dart';

/// Profile tab (shell route `/profile`).
///
/// Shows an avatar placeholder, the current subscription tier chip, autofill
/// usage, an Upgrade CTA (hidden on Pro) and a mock Sign out. The bottom nav is
/// owned by the shell.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static String _tierName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return 'Starter';
      case SubscriptionTier.plus:
        return 'Plus';
      case SubscriptionTier.pro:
        return 'Pro';
    }
  }

  static String _usageLabel(UserAccount account) {
    final int? limit = account.autofillLimit;
    if (limit == null) return 'Unlimited autofills';
    return '${account.autofillUsed} of $limit used';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);
    final bool isPro = account.tier == SubscriptionTier.pro;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person_outline,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_tierName(account.tier)} plan',
                    style: AppTextStyles.labelLg
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.bolt, color: AppColors.successDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'AI autofills',
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.mutedText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _usageLabel(account),
                        style: AppTextStyles.bodyMd
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!isPro)
            ElevatedButton.icon(
              onPressed: () => context.go('/pricing'),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Upgrade'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          if (!isPro) const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(accountProvider.notifier).continueAsGuest();
              context.go('/');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.outlineVariant),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
