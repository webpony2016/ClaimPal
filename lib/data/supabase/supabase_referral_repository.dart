import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/rewards_summary.dart';
import '../repositories/referral_repository.dart';
import 'supabase_referral_mapper.dart';

/// Supabase-backed [ReferralRepository] using the `public.referrals` table.
class SupabaseReferralRepository implements ReferralRepository {
  SupabaseReferralRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<RewardsSummary> getRewards() async {
    final user = _requireUser();
    final rows = await _client
        .from('referrals')
        .select('referrer_id, referee_id, status, created_at')
        .eq('referrer_id', user.id)
        .order('created_at', ascending: false);

    return SupabaseReferralMapper.toRewardsSummary(
      currentUserId: user.id,
      rows: rows.cast<Map<String, dynamic>>().map(Map<String, dynamic>.from),
      referralLink: await generateLink(),
    );
  }

  @override
  Future<String> generateLink() async {
    final user = _requireUser();
    return 'https://claimpal.app/r/${Uri.encodeComponent(user.id)}';
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No active Supabase user session found.');
    }
    return user;
  }
}