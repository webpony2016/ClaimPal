import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_account.dart';

/// Per-tier monthly autofill limits. `null` means unlimited.
int? _limitForTier(SubscriptionTier tier) {
  switch (tier) {
    case SubscriptionTier.starter:
      return 2;
    case SubscriptionTier.plus:
      return 5;
    case SubscriptionTier.pro:
      return null;
  }
}

/// Holds the current [UserAccount] and the credit/upgrade logic that mutates it.
class AccountNotifier extends Notifier<UserAccount> {
  @override
  UserAccount build() => const UserAccount.guest();

  /// Converts the guest into a registered account. Stays on the starter tier
  /// (limit 2, used 0).
  void register() {
    state = state.copyWith(isGuest: false);
  }

  /// Resets to a fresh guest account.
  void continueAsGuest() {
    state = const UserAccount.guest();
  }

  /// Consumes one autofill credit. Pro (unlimited) accounts are unaffected.
  void useAutofillCredit() {
    if (state.autofillLimit == null) return; // unlimited (pro)
    state = state.copyWith(autofillUsed: state.autofillUsed + 1);
  }

  /// Upgrades to [tier], applying the matching autofill limit and resetting
  /// usage to 0.
  ///
  /// Note: [UserAccount.copyWith] uses `autofillLimit ?? this.autofillLimit`,
  /// so it cannot set the limit back to `null` (the pro/unlimited case). We
  /// therefore construct a new [UserAccount] directly here.
  void upgradeTo(SubscriptionTier tier) {
    state = UserAccount(
      isGuest: state.isGuest,
      tier: tier,
      autofillUsed: 0,
      autofillLimit: _limitForTier(tier),
    );
  }
}

/// The current user account.
final accountProvider = NotifierProvider<AccountNotifier, UserAccount>(
  AccountNotifier.new,
);
