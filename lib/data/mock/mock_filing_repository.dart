import '../models/claim_progress.dart';
import '../models/filing_draft.dart';
import '../repositories/filing_repository.dart';
import 'mock_data.dart';

/// In-memory [FilingRepository]. Tracks which lawsuit ids have been submitted.
class MockFilingRepository implements FilingRepository {
  MockFilingRepository();

  // Records submitted lawsuit ids. Consumed by the "My Claims" screen
  // (Task 5.11) to list filings in progress; surfaced via [submittedLawsuitIds].
  final Set<String> _submitted = <String>{};

  /// Lawsuit ids that have been submitted via [submit], for the My Claims list.
  Set<String> get submittedLawsuitIds => Set.unmodifiable(_submitted);

  @override
  Future<FilingDraft> getDraft(String lawsuitId) async {
    await Future<void>.delayed(kMockLatency);
    if (kMockSimulateFailure) {
      throw StateError('Mock failure: getDraft');
    }
    return FilingDraft(
      lawsuitId: lawsuitId,
      fullName: 'Jordan Smith',
      address: '123 Market St, San Francisco, CA',
      actionRequiredFields: const {'Purchase Year': null},
      uploadedFileName: null,
      signatureData: null,
    );
  }

  @override
  Future<void> submit(FilingDraft draft) async {
    await Future<void>.delayed(kMockLatency);
    if (kMockSimulateFailure) {
      throw StateError('Mock failure: submit');
    }
    _submitted.add(draft.lawsuitId);
  }

  @override
  Future<List<String>> submittedClaimIds() async {
    await Future<void>.delayed(kMockLatency);
    if (kMockSimulateFailure) {
      throw StateError('Mock failure: submittedClaimIds');
    }
    return _submitted.toList();
  }

  @override
  Stream<ClaimProgress> watchProgress(String lawsuitId) {
    if (kMockSimulateFailure) {
      return Stream.error(StateError('Mock failure: watchProgress'));
    }
    // Demo default: a submitted (or any) claim begins at the AI-submitted stage.
    return Stream.value(
      const ClaimProgress(currentStage: ClaimStage.aiSubmitted),
    );
  }
}
