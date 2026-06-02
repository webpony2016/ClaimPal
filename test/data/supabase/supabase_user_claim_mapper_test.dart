import 'package:claimpal/data/models/claim_progress.dart';
import 'package:claimpal/data/models/user_claim.dart';
import 'package:claimpal/data/supabase/supabase_user_claim_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps Supabase user_claim row into a paid UserClaim snapshot', () {
    final claim = SupabaseUserClaimMapper.toUserClaim(<String, dynamic>{
      'id': 'claim-1',
      'settlement_id': 'lawsuit-1',
      'status': 'payout_sent',
      'current_stage': 'payout_sent',
      'filing_data': <String, dynamic>{
        'full_name': 'Jordan Smith',
        'address': '123 Market St',
        'action_required_fields': <String, dynamic>{'Purchase Year': '2019'},
        'uploaded_file_name': 'receipt.pdf',
        'signature_data': 'sig:3',
      },
      'attempt_count': 2,
      'submitted_at': '2026-05-31T08:00:00Z',
      'reviewed_at': '2026-05-31T09:00:00Z',
      'rejected_at': null,
      'payout_confirmed_at': '2026-05-31T10:00:00Z',
      'payout_amount': 42.5,
      'created_at': '2026-05-31T08:00:00Z',
      'updated_at': '2026-05-31T10:00:00Z',
    });

    expect(claim.status, UserClaimStatus.payoutSent);
    expect(claim.currentStage, ClaimStage.payoutSent);
    expect(claim.isPaid, isTrue);
    expect(claim.confirmedPayoutAmount, 42.5);
    expect(claim.actionRequiredFields['Purchase Year'], '2019');
    expect(claim.uploadedFileName, 'receipt.pdf');
    expect(claim.signatureData, 'sig:3');
    expect(claim.attemptCount, 2);
  });

  test('claimStageToSql preserves existing Flutter stepper order', () {
    expect(
      ClaimStage.values.map(SupabaseUserClaimMapper.claimStageToSql),
      <String>[
        'ai_submitted',
        'court_review',
        'settlement_approved',
        'payout_sent',
      ],
    );
  });
}
