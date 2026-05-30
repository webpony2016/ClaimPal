import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/rewards_summary.dart';
import '../../data/providers.dart';

final _currency = NumberFormat.currency(symbol: '\$');

/// Focused earnings / wallet screen (route `/wallet`).
///
/// Shows the balance summary, a (mock) withdraw action and the list of
/// referral invites with a credited/pending status chip each.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: rewardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          onRetry: () => ref.invalidate(rewardsProvider),
        ),
        data: (rewards) => _WalletBody(rewards: rewards),
      ),
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody({required this.rewards});

  final RewardsSummary rewards;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'BALANCE',
                style:
                    AppTextStyles.labelSm.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 4),
              Text(
                _currency.format(rewards.totalEarned),
                style: AppTextStyles.headlineLg
                    .copyWith(color: AppColors.successDark),
              ),
              const SizedBox(height: 4),
              Text(
                '${_currency.format(rewards.pending)} pending',
                style:
                    AppTextStyles.bodyMd.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Withdrawal requested')),
          ),
          icon: const Icon(Icons.savings_outlined),
          label: const Text('Withdraw'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successDark,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 24),
        Text('Invites', style: AppTextStyles.headlineSm),
        const SizedBox(height: 8),
        if (rewards.invites.isEmpty)
          const _EmptyInvites()
        else
          for (final invite in rewards.invites)
            _InviteRow(invite: invite),
      ],
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite});

  final ReferralInvite invite;

  @override
  Widget build(BuildContext context) {
    final bool credited = invite.status == RewardStatus.credited;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: AppColors.surfaceContainerLow,
            child: const Icon(Icons.person_outline, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(invite.maskedId, style: AppTextStyles.bodyMd),
          ),
          _StatusChip(credited: credited),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.credited});

  final bool credited;

  @override
  Widget build(BuildContext context) {
    final Color color = credited ? AppColors.successDark : AppColors.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        credited ? 'Credited' : 'Pending',
        style: AppTextStyles.labelSm.copyWith(color: color),
      ),
    );
  }
}

class _EmptyInvites extends StatelessWidget {
  const _EmptyInvites();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: <Widget>[
          const Icon(Icons.group_outlined, size: 40, color: AppColors.expired),
          const SizedBox(height: 12),
          Text(
            'No invites yet',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.mutedText),
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
              "Couldn't load your wallet",
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
