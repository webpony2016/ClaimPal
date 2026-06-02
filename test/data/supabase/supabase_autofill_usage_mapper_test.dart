import 'package:claimpal/data/models/user_account.dart';
import 'package:claimpal/data/supabase/supabase_autofill_usage_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a starter usage RPC row into a snapshot', () {
    final snapshot = SupabaseAutofillUsageMapper.toSnapshot(
      <String, dynamic>{
        'effective_tier': 'starter',
        'autofill_limit': 2,
        'scope': 'starter_lifetime',
        'period_start': '1970-01-01',
        'used_count': 1,
      },
    );

    expect(snapshot.effectiveTier, SubscriptionTier.starter);
    expect(snapshot.autofillLimit, 2);
    expect(snapshot.scope, 'starter_lifetime');
    expect(snapshot.usedCount, 1);
  });

  test('maps a pro usage RPC row with unlimited credits', () {
    final snapshot = SupabaseAutofillUsageMapper.toSnapshot(
      <String, dynamic>{
        'effective_tier': 'pro',
        'autofill_limit': null,
        'scope': 'pro_unlimited',
        'period_start': '2026-05-01',
        'used_count': 0,
      },
    );

    expect(snapshot.effectiveTier, SubscriptionTier.pro);
    expect(snapshot.autofillLimit, isNull);
    expect(snapshot.scope, 'pro_unlimited');
    expect(snapshot.usedCount, 0);
  });
}