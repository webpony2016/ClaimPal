import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/autofill_usage_snapshot.dart';
import '../../data/models/user_account.dart';
import '../../data/providers.dart';
import '../../data/supabase/supabase_account_mapper.dart';

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
  bool _hydrating = false;

  @override
  UserAccount build() {
    if (ref.watch(useSupabaseDataProvider)) {
      unawaited(_hydrateFromSupabase());
    }
    return const UserAccount.guest();
  }

  /// Converts the guest into a registered account. Stays on the starter tier
  /// (limit 2, used 0).
  void register() {
    state = state.copyWith(isGuest: false);
  }

  /// Resets to a fresh guest account.
  void continueAsGuest() {
    state = const UserAccount.guest();
    if (ref.read(useSupabaseDataProvider)) {
      unawaited(_resetSupabaseSession());
    }
  }

  /// Consumes one autofill credit. Pro (unlimited) accounts are unaffected.
  Future<void> useAutofillCredit() async {
    if (state.autofillLimit == null) return; // unlimited (pro)

    final usageStore = ref.read(supabaseAutofillUsageStoreProvider);
    if (usageStore == null) {
      state = state.copyWith(autofillUsed: state.autofillUsed + 1);
      return;
    }

    final snapshot = await usageStore.consumeCredit();
    if (!ref.mounted) {
      return;
    }

    state = _accountFromSnapshot(snapshot);
  }

  Future<void> refreshFromSupabase() async {
    if (!ref.read(useSupabaseDataProvider)) {
      return;
    }
    await _hydrateFromSupabase();
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

  Future<void> _hydrateFromSupabase() async {
    if (_hydrating) {
      return;
    }
    _hydrating = true;
    try {
      final client = ref.read(supabaseClientProvider);
      final usageStore = ref.read(supabaseAutofillUsageStoreProvider);
      final user = client?.auth.currentUser;
      if (client == null || user == null) {
        return;
      }

      final usageSnapshot = usageStore == null
          ? null
          : await usageStore.getCurrentUsage();

      final row = await client
          .from('profiles')
          .select('id, email, premium_tier, premium_until')
          .eq('id', user.id)
          .maybeSingle();

      if (!ref.mounted) {
        return;
      }

      state = SupabaseAccountMapper.toUserAccount(
        row == null ? null : Map<String, dynamic>.from(row),
        autofillUsed: state.autofillUsed,
        fallbackIsGuest: state.isGuest,
        user: user,
        usageSnapshot: usageSnapshot,
      );
    } finally {
      _hydrating = false;
    }
  }

  Future<void> _resetSupabaseSession() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      return;
    }

    try {
      await client.auth.signOut();
      await client.auth.signInAnonymously();
      if (ref.mounted) {
        await _hydrateFromSupabase();
      }
    } on AuthException {
      // Keep the local guest state even if the remote reset fails.
    }
  }

  UserAccount _accountFromSnapshot(AutofillUsageSnapshot snapshot) {
    return UserAccount(
      isGuest: state.isGuest,
      tier: snapshot.effectiveTier,
      autofillUsed: snapshot.usedCount,
      autofillLimit: snapshot.autofillLimit,
    );
  }
}

/// The current user account.
final accountProvider = NotifierProvider<AccountNotifier, UserAccount>(
  AccountNotifier.new,
);
