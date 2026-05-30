import '../models/rewards_summary.dart';
import '../repositories/referral_repository.dart';
import 'mock_data.dart';

/// Shareable referral link used by the mock.
const String kMockReferralLink = 'https://claimpal.com/r/abc123';

/// In-memory [ReferralRepository]. Invite ids are masked (no real PII).
class MockReferralRepository implements ReferralRepository {
  const MockReferralRepository();

  @override
  Future<RewardsSummary> getRewards() async {
    await Future<void>.delayed(kMockLatency);
    if (kMockSimulateFailure) {
      throw StateError('Mock failure: getRewards');
    }
    return const RewardsSummary(
      totalEarned: 120.0,
      pending: 30.0,
      referralLink: kMockReferralLink,
      invites: [
        ReferralInvite(maskedId: 'user_8f3a', status: RewardStatus.credited),
        ReferralInvite(maskedId: 'user_b21c', status: RewardStatus.pending),
      ],
    );
  }

  @override
  Future<String> generateLink() async {
    await Future<void>.delayed(kMockLatency);
    if (kMockSimulateFailure) {
      throw StateError('Mock failure: generateLink');
    }
    return kMockReferralLink;
  }
}
