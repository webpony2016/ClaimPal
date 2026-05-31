import 'package:claimpal/data/models/rewards_summary.dart';
import 'package:claimpal/data/supabase/supabase_referral_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps referral rows into wallet totals and masked invites', () {
    final summary = SupabaseReferralMapper.toRewardsSummary(
      currentUserId: 'user-a',
      referralLink: 'https://claimpal.app/r/user-a',
      rows: <Map<String, dynamic>>[
        <String, dynamic>{
          'referrer_id': 'user-a',
          'referee_id': '11111111-2222-3333-4444-555555555555',
          'status': 'first_claim_filed',
        },
        <String, dynamic>{
          'referrer_id': 'user-a',
          'referee_id': '99999999-aaaa-bbbb-cccc-dddddddddddd',
          'status': 'registered',
        },
      ],
    );

    expect(summary.totalEarned, 30.0);
    expect(summary.pending, 30.0);
    expect(summary.referralLink, contains('claimpal'));
    expect(summary.invites, hasLength(2));
    expect(summary.invites.first.status, RewardStatus.credited);
    expect(summary.invites.last.status, RewardStatus.pending);
    for (final invite in summary.invites) {
      expect(invite.maskedId, startsWith('user_'));
      expect(invite.maskedId, isNot(contains('@')));
    }
  });
}