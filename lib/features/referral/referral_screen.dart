import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/privacy_badge.dart';
import '../../data/models/rewards_summary.dart';
import '../../data/providers.dart';

final _currency = NumberFormat.currency(symbol: '\$');

/// Combined referral + rewards screen (route `/referral`).
///
/// Surfaces the user's total earned / pending rewards, the "Give 1 Month, Get
/// 1 Month" referral offer (1 month of Plus for both parties), a copyable
/// referral link, social share shortcuts and a link to the wallet.
class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Wallet',
            onPressed: () => context.go('/wallet'),
          ),
        ],
      ),
      body: rewardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          onRetry: () => ref.invalidate(rewardsProvider),
        ),
        data: (rewards) => _ReferralBody(rewards: rewards),
      ),
    );
  }
}

class _ReferralBody extends StatelessWidget {
  const _ReferralBody({required this.rewards});

  final RewardsSummary rewards;

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Earnings summary.
          Row(
            children: <Widget>[
              Expanded(
                child: _EarningsStat(
                  label: 'Total Earned',
                  value: _currency.format(rewards.totalEarned),
                  color: AppColors.successDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EarningsStat(
                  label: 'Pending',
                  value: _currency.format(rewards.pending),
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _snack(context, 'Withdrawal requested'),
            icon: const Icon(Icons.savings_outlined),
            label: const Text('Withdraw'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successDark,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 24),
          // Core referral offer card.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'LIMITED TIME OFFER',
                    style: AppTextStyles.labelSm.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Give 1 Month, Get 1 Month. Unlimited times.',
                  style:
                      AppTextStyles.headlineSm.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'When a friend files their first claim, you BOTH get 1 month '
                  'of Plus free. Keep inviting, keep stacking.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: PrivacyBadge()),
          const SizedBox(height: 24),
          Text(
            'Your unique invite link',
            style: AppTextStyles.labelLg.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 8),
          _LinkField(
            link: rewards.referralLink,
            onCopy: () async {
              await Clipboard.setData(
                ClipboardData(text: rewards.referralLink),
              );
              if (context.mounted) _snack(context, 'Link copied');
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Share via',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLg.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _ShareIcon(
                icon: Icons.chat_bubble_outline,
                label: 'Messages',
                onTap: () => _snack(context, 'Shared via Messages'),
              ),
              _ShareIcon(
                icon: Icons.sms_outlined,
                label: 'WhatsApp',
                onTap: () => _snack(context, 'Shared via WhatsApp'),
              ),
              _ShareIcon(
                icon: Icons.send,
                label: 'Messenger',
                onTap: () => _snack(context, 'Shared via Messenger'),
              ),
              _ShareIcon(
                icon: Icons.mail_outline,
                label: 'Email',
                onTap: () => _snack(context, 'Shared via Email'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.go('/wallet'),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('View wallet'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.outlineVariant),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsStat extends StatelessWidget {
  const _EarningsStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelSm.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineMd.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _LinkField extends StatelessWidget {
  const _LinkField({required this.link, required this.onCopy});

  final String link;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              link,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onCopy,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}

class _ShareIcon extends StatelessWidget {
  const _ShareIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              "Couldn't load your rewards",
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
