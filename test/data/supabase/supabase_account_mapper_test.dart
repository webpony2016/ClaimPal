import 'package:claimpal/data/models/user_account.dart';
import 'package:claimpal/data/supabase/supabase_account_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 5, 30);

  test('falls back to starter when no profile row is available', () {
    final account = SupabaseAccountMapper.toUserAccount(
      null,
      user: null,
      fallbackIsGuest: true,
      now: now,
    );

    expect(account.isGuest, isTrue);
    expect(account.tier, SubscriptionTier.starter);
    expect(account.autofillLimit, 2);
  });

  test('maps active premium_until to plus tier', () {
    final account = SupabaseAccountMapper.toUserAccount(
      <String, dynamic>{
        'premium_tier': 'plus',
        'premium_until': '2026-06-15T00:00:00Z',
      },
      user: null,
      fallbackIsGuest: false,
      autofillUsed: 1,
      now: now,
    );

    expect(account.isGuest, isFalse);
    expect(account.tier, SubscriptionTier.plus);
    expect(account.autofillLimit, 5);
    expect(account.autofillUsed, 1);
  });

  test('treats expired plus access as starter', () {
    final account = SupabaseAccountMapper.toUserAccount(
      <String, dynamic>{
        'premium_tier': 'plus',
        'premium_until': '2026-05-01T00:00:00Z',
      },
      user: null,
      fallbackIsGuest: false,
      now: now,
    );

    expect(account.tier, SubscriptionTier.starter);
    expect(account.autofillLimit, 2);
  });

  test('keeps pro unlimited regardless of premium_until', () {
    final account = SupabaseAccountMapper.toUserAccount(
      <String, dynamic>{
        'premium_tier': 'pro',
        'premium_until': null,
      },
      user: null,
      fallbackIsGuest: false,
      now: now,
    );

    expect(account.tier, SubscriptionTier.pro);
    expect(account.autofillLimit, isNull);
  });
}