import 'user_account.dart' show SubscriptionTier;

/// Immutable description of a purchasable subscription plan.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.tier,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.monthlyAutofills,
  });

  final SubscriptionTier tier;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;

  /// Number of autofills included per month. `null` means unlimited.
  final int? monthlyAutofills;

  SubscriptionPlan copyWith({
    SubscriptionTier? tier,
    double? monthlyPrice,
    double? yearlyPrice,
    List<String>? features,
    int? monthlyAutofills,
  }) {
    return SubscriptionPlan(
      tier: tier ?? this.tier,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      yearlyPrice: yearlyPrice ?? this.yearlyPrice,
      features: features ?? this.features,
      monthlyAutofills: monthlyAutofills ?? this.monthlyAutofills,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionPlan &&
        runtimeType == other.runtimeType &&
        tier == other.tier &&
        monthlyPrice == other.monthlyPrice &&
        yearlyPrice == other.yearlyPrice &&
        monthlyAutofills == other.monthlyAutofills &&
        _listEquals(features, other.features);
  }

  @override
  int get hashCode => Object.hash(
        tier,
        monthlyPrice,
        yearlyPrice,
        monthlyAutofills,
        Object.hashAll(features),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
