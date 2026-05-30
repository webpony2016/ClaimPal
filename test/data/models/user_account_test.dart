import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/data/models/user_account.dart';

void main() {
  test('starter has limit 2; pro is unlimited (null limit)', () {
    const starter = UserAccount(
      isGuest: false,
      tier: SubscriptionTier.starter,
      autofillUsed: 0,
      autofillLimit: 2,
    );
    expect(starter.hasAutofillCredit, isTrue);
    const used = UserAccount(
      isGuest: false,
      tier: SubscriptionTier.starter,
      autofillUsed: 2,
      autofillLimit: 2,
    );
    expect(used.hasAutofillCredit, isFalse);
    const pro = UserAccount(
      isGuest: false,
      tier: SubscriptionTier.pro,
      autofillUsed: 99,
      autofillLimit: null,
    );
    expect(pro.hasAutofillCredit, isTrue);
  });

  test('guest factory', () {
    const g = UserAccount.guest();
    expect(g.isGuest, isTrue);
    expect(g.autofillLimit, 2);
  });

  test('copyWith changes fields', () {
    const g = UserAccount.guest();
    final upgraded = g.copyWith(
      isGuest: false,
      tier: SubscriptionTier.plus,
      autofillUsed: 1,
    );
    expect(upgraded.isGuest, isFalse);
    expect(upgraded.tier, SubscriptionTier.plus);
    expect(upgraded.autofillUsed, 1);
    expect(upgraded.autofillLimit, 2);
  });

  test('equality and hashCode', () {
    const a = UserAccount(
      isGuest: false,
      tier: SubscriptionTier.pro,
      autofillUsed: 3,
      autofillLimit: null,
    );
    const b = UserAccount(
      isGuest: false,
      tier: SubscriptionTier.pro,
      autofillUsed: 3,
      autofillLimit: null,
    );
    const c = UserAccount(
      isGuest: false,
      tier: SubscriptionTier.pro,
      autofillUsed: 4,
      autofillLimit: null,
    );
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });
}
