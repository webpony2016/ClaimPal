import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/subscription_plan.dart';
import '../../data/models/user_account.dart';
import '../../data/providers.dart';
import '../account/account_provider.dart';

/// Pricing / subscription screen (route `/pricing`).
///
/// Shows a monthly/yearly billing toggle and the three subscription plans from
/// [subscriptionPlansProvider]. The user's current tier is highlighted and its
/// button is disabled ("Current plan"); choosing another plan upgrades the
/// account via [AccountNotifier.upgradeTo].
class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  bool _yearly = false;

  String _tierName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return 'Starter';
      case SubscriptionTier.plus:
        return 'Plus';
      case SubscriptionTier.pro:
        return 'Pro';
    }
  }

  String _autofillQuota(SubscriptionPlan plan) {
    final int? quota = plan.monthlyAutofills;
    if (quota == null) return 'Unlimited filings';
    if (plan.tier == SubscriptionTier.starter) return '$quota filings';
    return '$quota / month';
  }

  void _choose(SubscriptionPlan plan) {
    ref.read(accountProvider.notifier).upgradeTo(plan.tier);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upgraded to ${_tierName(plan.tier)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final currentTier = ref.watch(accountProvider).tier;

    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          onRetry: () => ref.invalidate(subscriptionPlansProvider),
        ),
        data: (plans) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Unlock Your Unclaimed Cash',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Professional legal monitoring for every consumer.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 24),
              _BillingToggle(
                yearly: _yearly,
                onChanged: (value) => setState(() => _yearly = value),
              ),
              const SizedBox(height: 24),
              for (final plan in plans) ...<Widget>[
                _PlanCard(
                  planName: _tierName(plan.tier),
                  plan: plan,
                  yearly: _yearly,
                  autofillQuota: _autofillQuota(plan),
                  isCurrent: plan.tier == currentTier,
                  onChoose: () => _choose(plan),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({required this.yearly, required this.onChanged});

  final bool yearly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ToggleSegment(
              label: 'Monthly',
              selected: !yearly,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ToggleSegment(
              label: 'Yearly (Save 30%)',
              selected: yearly,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelLg.copyWith(
            color: selected ? AppColors.primary : AppColors.mutedText,
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.planName,
    required this.plan,
    required this.yearly,
    required this.autofillQuota,
    required this.isCurrent,
    required this.onChoose,
  });

  final String planName;
  final SubscriptionPlan plan;
  final bool yearly;
  final String autofillQuota;
  final bool isCurrent;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final double price = yearly ? plan.yearlyPrice : plan.monthlyPrice;
    final String period = yearly ? '/yr' : '/mo';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withValues(alpha: 0.04)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.outlineVariant,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(planName, style: AppTextStyles.headlineSm),
              ),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Current',
                    style: AppTextStyles.labelSm.copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                period,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(
                Icons.bolt,
                size: 18,
                color: AppColors.successDark,
              ),
              const SizedBox(width: 8),
              Text(
                autofillQuota,
                style:
                    AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final feature in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.successDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(feature, style: AppTextStyles.bodySm),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (isCurrent)
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                disabledBackgroundColor: AppColors.surfaceContainerLow,
                disabledForegroundColor: AppColors.expired,
              ),
              child: const Text('Current plan'),
            )
          else
            ElevatedButton(
              onPressed: onChoose,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(plan.tier == SubscriptionTier.starter
                  ? 'Choose'
                  : 'Upgrade'),
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
              "Couldn't load plans",
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
