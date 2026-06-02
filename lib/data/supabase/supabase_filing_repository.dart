import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/claim_progress.dart';
import '../models/filing_draft.dart';
import '../models/user_claim.dart';
import '../repositories/filing_repository.dart';
import 'supabase_user_claim_mapper.dart';

class SupabaseFilingRepository implements FilingRepository {
  SupabaseFilingRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'user_claims';
  static const String _selectColumns =
      'id, settlement_id, status, current_stage, filing_data, attempt_count, '
      'submitted_at, reviewed_at, rejected_at, payout_confirmed_at, '
      'payout_amount, created_at, updated_at';

  @override
  Future<FilingDraft> getDraft(String lawsuitId) async {
    final user = _client.auth.currentUser;
    final row = await _client
        .from(_table)
        .select(_selectColumns)
        .eq('settlement_id', lawsuitId)
        .maybeSingle();

    final UserClaim? claim = row == null
        ? null
        : SupabaseUserClaimMapper.toUserClaim(Map<String, dynamic>.from(row));
    final actionFields = claim?.actionRequiredFields ?? const <String, String?>{};

    return FilingDraft(
      lawsuitId: lawsuitId,
      fullName:
          claim?.fullName ?? _displayNameFor(user) ?? 'ClaimPal Member',
      address: claim?.address ?? 'Add your address to continue',
      actionRequiredFields: actionFields.isEmpty
          ? const <String, String?>{'Purchase Year': null}
          : actionFields,
      uploadedFileName: claim?.uploadedFileName,
      signatureData: claim?.signatureData,
    );
  }

  @override
  Future<void> submit(FilingDraft draft) async {
    final filingData = <String, dynamic>{
      'full_name': draft.fullName,
      'address': draft.address,
      'action_required_fields': draft.actionRequiredFields,
      'uploaded_file_name': draft.uploadedFileName,
      'signature_data': draft.signatureData,
    };

    await _client.rpc(
      'submit_user_claim',
      params: <String, dynamic>{
        'p_settlement_id': draft.lawsuitId,
        'p_filing_data': filingData,
      },
    );
  }

  @override
  Future<List<String>> submittedClaimIds() async {
    final rows = await _client
        .from(_table)
        .select(_selectColumns)
        .order('updated_at', ascending: false);
    final claims = rows
        .cast<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .map(SupabaseUserClaimMapper.toUserClaim);

    return claims
        .where((claim) => claim.showsInClaimList)
        .map((claim) => claim.lawsuitId)
        .toList(growable: false);
  }

  @override
  Stream<ClaimProgress> watchProgress(String lawsuitId) async* {
    final row = await _client
        .from(_table)
        .select(_selectColumns)
        .eq('settlement_id', lawsuitId)
        .maybeSingle();

    final ClaimStage stage;
    if (row == null) {
      stage = ClaimStage.aiSubmitted;
    } else {
      final claim =
          SupabaseUserClaimMapper.toUserClaim(Map<String, dynamic>.from(row));
      stage = claim.currentStage ?? ClaimStage.aiSubmitted;
    }

    yield ClaimProgress(currentStage: stage);
  }

  String? _displayNameFor(User? user) {
    if (user == null) {
      return null;
    }

    final metadata = user.userMetadata;
    final fullName = metadata?['full_name']?.toString();
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    final name = metadata?['name']?.toString();
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }

    final email = user.email;
    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }
    return null;
  }
}
