import 'user_account.dart';

/// Current persisted AI autofill usage for the user's active billing bucket.
class AutofillUsageSnapshot {
  const AutofillUsageSnapshot({
    required this.effectiveTier,
    required this.autofillLimit,
    required this.usedCount,
    required this.scope,
    required this.periodStart,
  });

  final SubscriptionTier effectiveTier;
  final int? autofillLimit;
  final int usedCount;
  final String scope;
  final DateTime periodStart;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutofillUsageSnapshot &&
          runtimeType == other.runtimeType &&
          effectiveTier == other.effectiveTier &&
          autofillLimit == other.autofillLimit &&
          usedCount == other.usedCount &&
          scope == other.scope &&
          periodStart == other.periodStart;

  @override
  int get hashCode => Object.hash(
        effectiveTier,
        autofillLimit,
        usedCount,
        scope,
        periodStart,
      );
}