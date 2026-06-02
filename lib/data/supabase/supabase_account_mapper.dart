import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/autofill_usage_snapshot.dart';
import '../models/user_account.dart';

/// Maps Supabase auth/profile data into the app's [UserAccount] model.
class SupabaseAccountMapper {
  const SupabaseAccountMapper._();

  static UserAccount toUserAccount(
    Map<String, dynamic>? profileRow, {
    required User? user,
    required bool fallbackIsGuest,
    int autofillUsed = 0,
    AutofillUsageSnapshot? usageSnapshot,
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now().toUtc();
    final remoteGuest = _isAnonymousUser(user);
    final isGuest = fallbackIsGuest ? remoteGuest : false;
    final tier = usageSnapshot?.effectiveTier ??
        _resolveTier(profileRow, referenceNow);

    return UserAccount(
      isGuest: isGuest,
      tier: tier,
      autofillUsed: usageSnapshot?.usedCount ?? autofillUsed,
      autofillLimit: usageSnapshot?.autofillLimit ?? _limitForTier(tier),
    );
  }

  static SubscriptionTier _resolveTier(
    Map<String, dynamic>? profileRow,
    DateTime referenceNow,
  ) {
    final rawTier = profileRow?['premium_tier']?.toString() ?? 'starter';
    final premiumUntil = _readDateTime(profileRow?['premium_until']);

    if (rawTier == 'pro') {
      return SubscriptionTier.pro;
    }

    if (premiumUntil != null && premiumUntil.isAfter(referenceNow)) {
      return SubscriptionTier.plus;
    }

    return SubscriptionTier.starter;
  }

  static bool _isAnonymousUser(User? user) {
    if (user == null) {
      return true;
    }

    final provider = user.appMetadata['provider']?.toString();
    return provider == 'anonymous';
  }

  static DateTime? _readDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.toUtc();
    }
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  static int? _limitForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return 2;
      case SubscriptionTier.plus:
        return 5;
      case SubscriptionTier.pro:
        return null;
    }
  }
}