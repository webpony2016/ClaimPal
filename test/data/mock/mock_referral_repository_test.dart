import 'package:claimpal/data/mock/mock_referral_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repo = MockReferralRepository();

  test('getRewards returns expected totals and a claimpal link', () async {
    final rewards = await repo.getRewards();
    expect(rewards.totalEarned, 120.0);
    expect(rewards.pending, 30.0);
    expect(rewards.referralLink, contains('claimpal'));
  });

  test('invite maskedIds contain no @ or real names', () async {
    final rewards = await repo.getRewards();
    expect(rewards.invites, isNotEmpty);
    for (final invite in rewards.invites) {
      expect(invite.maskedId, isNot(contains('@')));
      expect(invite.maskedId, startsWith('user_'));
    }
  });

  test('generateLink returns a claimpal link', () async {
    final link = await repo.generateLink();
    expect(link, contains('claimpal'));
  });
}
