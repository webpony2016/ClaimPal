/// Whether a referral reward has been paid out yet.
enum RewardStatus { pending, credited }

/// A single referred user and the state of their associated reward.
///
/// [maskedId] is already anonymized for display (e.g. "user_8f3a").
class ReferralInvite {
  const ReferralInvite({
    required this.maskedId,
    required this.status,
  });

  final String maskedId;
  final RewardStatus status;

  ReferralInvite copyWith({
    String? maskedId,
    RewardStatus? status,
  }) {
    return ReferralInvite(
      maskedId: maskedId ?? this.maskedId,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferralInvite &&
          runtimeType == other.runtimeType &&
          maskedId == other.maskedId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(maskedId, status);
}

/// Immutable summary of a user's referral earnings and invites.
class RewardsSummary {
  const RewardsSummary({
    required this.totalEarned,
    required this.pending,
    required this.referralLink,
    required this.invites,
  });

  final double totalEarned;
  final double pending;
  final String referralLink;
  final List<ReferralInvite> invites;

  RewardsSummary copyWith({
    double? totalEarned,
    double? pending,
    String? referralLink,
    List<ReferralInvite>? invites,
  }) {
    return RewardsSummary(
      totalEarned: totalEarned ?? this.totalEarned,
      pending: pending ?? this.pending,
      referralLink: referralLink ?? this.referralLink,
      invites: invites ?? this.invites,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RewardsSummary &&
        runtimeType == other.runtimeType &&
        totalEarned == other.totalEarned &&
        pending == other.pending &&
        referralLink == other.referralLink &&
        _listEquals(invites, other.invites);
  }

  @override
  int get hashCode => Object.hash(
        totalEarned,
        pending,
        referralLink,
        Object.hashAll(invites),
      );

  static bool _listEquals(List<ReferralInvite> a, List<ReferralInvite> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
