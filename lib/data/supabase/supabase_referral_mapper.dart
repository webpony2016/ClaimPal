import '../models/rewards_summary.dart';

/// Fixed wallet value shown in the mobile UI for one successful referral.
///
/// The database stores Plus-month rewards, while the current UI surfaces a
/// wallet summary in USD. We keep the product's existing display semantics by
/// using the same per-invite value that seeded the mock dashboard.
const double kReferralRewardValue = 30.0;

/// Maps Supabase `referrals` rows into the app-facing [RewardsSummary].
class SupabaseReferralMapper {
  const SupabaseReferralMapper._();

  static RewardsSummary toRewardsSummary({
    required String currentUserId,
    required Iterable<Map<String, dynamic>> rows,
    required String referralLink,
  }) {
    final invites = rows.map((row) => _toInvite(currentUserId, row)).toList();

    final creditedCount =
        invites.where((invite) => invite.status == RewardStatus.credited).length;
    final pendingCount = invites.length - creditedCount;

    return RewardsSummary(
      totalEarned: creditedCount * kReferralRewardValue,
      pending: pendingCount * kReferralRewardValue,
      referralLink: referralLink,
      invites: invites,
    );
  }

  static ReferralInvite _toInvite(
    String currentUserId,
    Map<String, dynamic> row,
  ) {
    final isReferrer = row['referrer_id']?.toString() == currentUserId;
    final otherPartyId = isReferrer
        ? row['referee_id']?.toString() ?? ''
        : row['referrer_id']?.toString() ?? '';
    final normalized = otherPartyId.replaceAll('-', '');
    final suffix = normalized.isEmpty
        ? 'anon'
        : normalized.substring(0, normalized.length >= 4 ? 4 : normalized.length);

    return ReferralInvite(
      maskedId: 'user_$suffix',
      status: _toRewardStatus(row['status']?.toString()),
    );
  }

  static RewardStatus _toRewardStatus(String? status) {
    switch (status) {
      case 'first_claim_filed':
        return RewardStatus.credited;
      case 'registered':
      default:
        return RewardStatus.pending;
    }
  }
}