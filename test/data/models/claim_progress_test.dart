import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/data/models/claim_progress.dart';

void main() {
  test('stageIndex matches enum order', () {
    const p = ClaimProgress(currentStage: ClaimStage.courtReview);
    expect(p.stageIndex, ClaimStage.values.indexOf(ClaimStage.courtReview));
    expect(p.stageIndex, 1);
  });

  test('advanced() progresses through all stages then caps', () {
    var p = const ClaimProgress(currentStage: ClaimStage.aiSubmitted);
    p = p.advanced();
    expect(p.currentStage, ClaimStage.courtReview);
    p = p.advanced();
    expect(p.currentStage, ClaimStage.settlementApproved);
    p = p.advanced();
    expect(p.currentStage, ClaimStage.payoutSent);
    // Cap: advancing the final stage stays at payoutSent.
    p = p.advanced();
    expect(p.currentStage, ClaimStage.payoutSent);
  });

  test('copyWith changes stage', () {
    const p = ClaimProgress(currentStage: ClaimStage.aiSubmitted);
    final updated = p.copyWith(currentStage: ClaimStage.payoutSent);
    expect(updated.currentStage, ClaimStage.payoutSent);
  });

  test('equality and hashCode', () {
    const a = ClaimProgress(currentStage: ClaimStage.courtReview);
    const b = ClaimProgress(currentStage: ClaimStage.courtReview);
    const c = ClaimProgress(currentStage: ClaimStage.payoutSent);
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });
}
