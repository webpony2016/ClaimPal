import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_claim.dart';
import '../repositories/user_claim_repository.dart';
import 'supabase_user_claim_mapper.dart';

class SupabaseUserClaimRepository implements UserClaimRepository {
  SupabaseUserClaimRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'user_claims';
  static const String _selectColumns =
      'id, settlement_id, status, current_stage, filing_data, attempt_count, '
      'submitted_at, reviewed_at, rejected_at, payout_confirmed_at, '
      'payout_amount, created_at, updated_at';

  @override
  Future<List<UserClaim>> getCurrentUserClaims() async {
    _requireUser();
    final rows = await _client
        .from(_table)
        .select(_selectColumns)
        .order('updated_at', ascending: false);

    return rows
        .cast<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .map(SupabaseUserClaimMapper.toUserClaim)
        .toList(growable: false);
  }

  @override
  Stream<List<UserClaim>> watchCurrentUserClaims() async* {
    yield await getCurrentUserClaims();
  }

  @override
  Future<UserClaim?> getByLawsuitId(String lawsuitId) async {
    _requireUser();
    final row = await _client
        .from(_table)
        .select(_selectColumns)
        .eq('settlement_id', lawsuitId)
        .maybeSingle();
    if (row == null) {
      return null;
    }

    return SupabaseUserClaimMapper.toUserClaim(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> markSelfIneligible(String lawsuitId) async {
    await _client.rpc(
      'mark_self_ineligible',
      params: <String, dynamic>{'p_settlement_id': lawsuitId},
    );
  }

  @override
  Future<void> clearSelfIneligible(String lawsuitId) async {
    await _client.rpc(
      'clear_self_ineligible',
      params: <String, dynamic>{'p_settlement_id': lawsuitId},
    );
  }

  @override
  Future<void> confirmPayout({
    required String lawsuitId,
    required double payoutAmount,
  }) async {
    await _client.rpc(
      'confirm_claim_payout',
      params: <String, dynamic>{
        'p_settlement_id': lawsuitId,
        'p_payout_amount': payoutAmount,
      },
    );
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No active Supabase user session found.');
    }
    return user;
  }
}
