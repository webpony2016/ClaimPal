import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/data/models/subscription_plan.dart';
import 'package:claimpal/data/models/user_account.dart';

void main() {
  SubscriptionPlan build() => const SubscriptionPlan(
        tier: SubscriptionTier.plus,
        monthlyPrice: 9.99,
        yearlyPrice: 99.0,
        features: ['Unlimited browsing', 'Priority support'],
        monthlyAutofills: 10,
      );

  test('copyWith changes fields', () {
    final p = build();
    final updated = p.copyWith(
      tier: SubscriptionTier.pro,
      monthlyAutofills: null,
    );
    expect(updated.tier, SubscriptionTier.pro);
    // copyWith uses `?? this.x`, so passing null keeps the prior value.
    expect(updated.monthlyAutofills, 10);
    expect(updated.monthlyPrice, 9.99);
  });

  test('equality and hashCode including features list', () {
    final a = build();
    final b = build();
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));

    final diff = a.copyWith(features: const ['Unlimited browsing']);
    expect(diff, isNot(equals(a)));
  });

  test('unlimited plan uses null autofills', () {
    const pro = SubscriptionPlan(
      tier: SubscriptionTier.pro,
      monthlyPrice: 19.99,
      yearlyPrice: 199.0,
      features: ['Everything'],
      monthlyAutofills: null,
    );
    expect(pro.monthlyAutofills, isNull);
  });
}
