/// Subscription tiers available to a user.
enum SubscriptionTier { starter, plus, pro }

/// Immutable representation of the current user's account state.
class UserAccount {
  const UserAccount({
    required this.isGuest,
    required this.tier,
    required this.autofillUsed,
    required this.autofillLimit,
  });

  /// A guest account: limited starter tier with 2 autofill credits.
  const UserAccount.guest()
      : isGuest = true,
        tier = SubscriptionTier.starter,
        autofillUsed = 0,
        autofillLimit = 2;

  final bool isGuest;
  final SubscriptionTier tier;
  final int autofillUsed;

  /// Maximum number of autofills allowed. `null` means unlimited.
  final int? autofillLimit;

  /// Whether the user still has autofill credit remaining.
  bool get hasAutofillCredit =>
      autofillLimit == null || autofillUsed < autofillLimit!;

  UserAccount copyWith({
    bool? isGuest,
    SubscriptionTier? tier,
    int? autofillUsed,
    int? autofillLimit,
  }) {
    return UserAccount(
      isGuest: isGuest ?? this.isGuest,
      tier: tier ?? this.tier,
      autofillUsed: autofillUsed ?? this.autofillUsed,
      autofillLimit: autofillLimit ?? this.autofillLimit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccount &&
          runtimeType == other.runtimeType &&
          isGuest == other.isGuest &&
          tier == other.tier &&
          autofillUsed == other.autofillUsed &&
          autofillLimit == other.autofillLimit;

  @override
  int get hashCode => Object.hash(isGuest, tier, autofillUsed, autofillLimit);
}
