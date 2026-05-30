import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../data/models/lawsuit.dart';
import '../../data/models/subscription_plan.dart';
import '../../data/models/user_account.dart';
import '../../data/providers.dart';
import '../account/account_provider.dart';

/// Presents the paywall half-sheet shown when a registered user is out of
/// autofill credit and tries to file [lawsuit].
///
/// On selecting a plan the account is upgraded, the sheet closes, and
/// navigation proceeds to `/filing/${lawsuit.id}`. A bottom "invite friends"
/// path closes the sheet and routes to `/referral`.
Future<void> showPaywallSheet(
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
      child: _PaywallSheetBody(lawsuit: lawsuit),
    ),
  );
}

class _PaywallSheetBody extends ConsumerStatefulWidget {
  const _PaywallSheetBody({required this.lawsuit});

  final Lawsuit lawsuit;

  @override
  ConsumerState<_PaywallSheetBody> createState() => _PaywallSheetBodyState();
}

class _PaywallSheetBodyState extends ConsumerState<_PaywallSheetBody> {
  bool _yearly = false;
  SubscriptionTier _selected = SubscriptionTier.plus;

  void _upgrade() {
    ref.read(accountProvider.notifier).upgradeTo(_selected);
    final id = widget.lawsuit.id;
    Navigator.of(context).pop();
    if (context.mounted) {
      context.go('/filing/$id');
    }
  }

  void _inviteFriends() {
    Navigator.of(context).pop();
    if (context.mounted) {
      context.go('/referral');
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            "You've used your 2 free filings",
            style: AppTextStyles.labelLg.copyWith(color: AppColors.successDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to submit this ${widget.lawsuit.payoutValue} claim.',
            style: AppTextStyles.headlineMd,
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a plan and file instantly, or earn a free month below.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 24),
          _BillingToggle(
            yearly: _yearly,
            onChanged: (value) => setState(() => _yearly = value),
          ),
          const SizedBox(height: 24),
          plansAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "Couldn't load plans. Please try again.",
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.bodyMd.copyWith(color: AppColors.mutedText),
              ),
            ),
            data: (plans) {
              final paidPlans = plans
                  .where((p) => p.tier != SubscriptionTier.starter)
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final plan in paidPlans) ...<Widget>[
                    _PlanCard(
                      plan: plan,
                      yearly: _yearly,
                      selected: _selected == plan.tier,
                      onTap: () => setState(() => _selected = plan.tier),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  _PayButton(
                    icon: Icons.apple,
                    label: 'Pay with Apple Pay',
                    onPressed: _upgrade,
                  ),
                  const SizedBox(height: 12),
                  _PayButton(
                    icon: Icons.android,
                    label: 'Pay with Google Pay',
                    filled: false,
                    onPressed: _upgrade,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          _ReferralPath(onTap: _inviteFriends),
        ],
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
    required this.plan,
    required this.yearly,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool yearly;
  final bool selected;
  final VoidCallback onTap;

  String get _planName {
    switch (plan.tier) {
      case SubscriptionTier.plus:
        return 'Plus Plan';
      case SubscriptionTier.pro:
        return 'Pro Plan';
      case SubscriptionTier.starter:
        return 'Starter Plan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = yearly ? plan.yearlyPrice : plan.monthlyPrice;
    final period = yearly ? '/yr' : '/mo';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(_planName, style: AppTextStyles.headlineSm),
                ),
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.outline,
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
          ],
        ),
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: AppColors.outlineVariant),
        minimumSize: const Size.fromHeight(52),
      ),
    );
  }
}

class _ReferralPath extends StatelessWidget {
  const _ReferralPath({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: AppColors.successDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Or invite friends to unlock 1 month of Plus free',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No payment needed',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
