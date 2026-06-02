import '../models/claim_progress.dart';
import '../models/user_claim.dart';

class SupabaseUserClaimMapper {
  const SupabaseUserClaimMapper._();

  static UserClaim toUserClaim(Map<String, dynamic> row) {
    return UserClaim(
      id: row['id'].toString(),
      lawsuitId: row['settlement_id'].toString(),
      status: userClaimStatusFromString(row['status']?.toString()),
      currentStage: claimStageFromString(row['current_stage']?.toString()),
      filingData: Map<String, dynamic>.from(
        row['filing_data'] as Map? ?? const <String, dynamic>{},
      ),
      attemptCount: (row['attempt_count'] as num?)?.toInt() ?? 0,
      submittedAt: _dateTimeOrNull(row['submitted_at']),
      reviewedAt: _dateTimeOrNull(row['reviewed_at']),
      rejectedAt: _dateTimeOrNull(row['rejected_at']),
      payoutConfirmedAt: _dateTimeOrNull(row['payout_confirmed_at']),
      payoutAmount: (row['payout_amount'] as num?)?.toDouble(),
      createdAt: _dateTimeOrNull(row['created_at']) ?? DateTime.now(),
      updatedAt: _dateTimeOrNull(row['updated_at']) ?? DateTime.now(),
    );
  }

  static UserClaimStatus userClaimStatusFromString(String? value) {
    switch (value) {
      case 'submitted':
        return UserClaimStatus.submitted;
      case 'under_review':
        return UserClaimStatus.underReview;
      case 'approved':
        return UserClaimStatus.approved;
      case 'payout_sent':
        return UserClaimStatus.payoutSent;
      case 'rejected':
        return UserClaimStatus.rejected;
      case 'self_ineligible':
        return UserClaimStatus.selfIneligible;
      case 'draft':
      case null:
        return UserClaimStatus.draft;
      default:
        throw StateError('Unknown user claim status: $value');
    }
  }

  static ClaimStage? claimStageFromString(String? value) {
    switch (value) {
      case 'ai_submitted':
        return ClaimStage.aiSubmitted;
      case 'court_review':
        return ClaimStage.courtReview;
      case 'settlement_approved':
        return ClaimStage.settlementApproved;
      case 'payout_sent':
        return ClaimStage.payoutSent;
      case null:
        return null;
      default:
        throw StateError('Unknown claim stage: $value');
    }
  }

  static String claimStageToSql(ClaimStage stage) {
    switch (stage) {
      case ClaimStage.aiSubmitted:
        return 'ai_submitted';
      case ClaimStage.courtReview:
        return 'court_review';
      case ClaimStage.settlementApproved:
        return 'settlement_approved';
      case ClaimStage.payoutSent:
        return 'payout_sent';
    }
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
