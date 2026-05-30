import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/data/models/rewards_summary.dart';

void main() {
  group('ReferralInvite', () {
    test('copyWith and equality', () {
      const a = ReferralInvite(maskedId: 'user_8f3a', status: RewardStatus.pending);
      const b = ReferralInvite(maskedId: 'user_8f3a', status: RewardStatus.pending);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      final credited = a.copyWith(status: RewardStatus.credited);
      expect(credited.status, RewardStatus.credited);
      expect(credited.maskedId, 'user_8f3a');
      expect(credited, isNot(equals(a)));
    });
  });

  group('RewardsSummary', () {
    RewardsSummary build() => const RewardsSummary(
          totalEarned: 50.0,
          pending: 10.0,
          referralLink: 'https://claimpal.app/r/abc',
          invites: [
            ReferralInvite(maskedId: 'user_8f3a', status: RewardStatus.credited),
            ReferralInvite(maskedId: 'user_2b1c', status: RewardStatus.pending),
          ],
        );

    test('copyWith changes fields', () {
      final s = build();
      final updated = s.copyWith(pending: 25.0);
      expect(updated.pending, 25.0);
      expect(updated.totalEarned, 50.0);
      expect(updated.invites, s.invites);
    });

    test('equality including invite list', () {
      final a = build();
      final b = build();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      final diff = a.copyWith(invites: const [
        ReferralInvite(maskedId: 'user_8f3a', status: RewardStatus.credited),
      ]);
      expect(diff, isNot(equals(a)));
    });
  });
}
