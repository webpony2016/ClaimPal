import '../models/rewards_summary.dart';

/// Read access to referral rewards and link generation.
abstract class ReferralRepository {
  /// Returns the current user's referral earnings and invites.
  Future<RewardsSummary> getRewards();

  /// Generates (or returns) the user's shareable referral link.
  Future<String> generateLink();
}
