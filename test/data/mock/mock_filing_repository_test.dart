import 'package:claimpal/data/mock/mock_filing_repository.dart';
import 'package:claimpal/data/models/claim_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('getDraft returns prefilled name/address with a null action field',
      () async {
    final repo = MockFilingRepository();
    final draft = await repo.getDraft('facebook-data-privacy');
    expect(draft.lawsuitId, 'facebook-data-privacy');
    expect(draft.fullName, 'Jordan Smith');
    expect(draft.address, '123 Market St, San Francisco, CA');
    expect(draft.actionRequiredFields.containsKey('Purchase Year'), isTrue);
    expect(draft.actionRequiredFields['Purchase Year'], isNull);
    expect(draft.uploadedFileName, isNull);
    expect(draft.signatureData, isNull);
  });

  test('after submit, watchProgress first emits aiSubmitted', () async {
    final repo = MockFilingRepository();
    final draft = await repo.getDraft('facebook-data-privacy');
    await repo.submit(draft);
    final progress = await repo.watchProgress(draft.lawsuitId).first;
    expect(progress.currentStage, ClaimStage.aiSubmitted);
  });

  test('submittedClaimIds is empty before any submit', () async {
    final repo = MockFilingRepository();
    expect(await repo.submittedClaimIds(), isEmpty);
  });

  test('submittedClaimIds includes a lawsuit id after submit', () async {
    final repo = MockFilingRepository();
    final draft = await repo.getDraft('facebook-data-privacy');
    await repo.submit(draft);
    expect(await repo.submittedClaimIds(), contains('facebook-data-privacy'));
  });
}
