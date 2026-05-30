import '../models/claim_progress.dart';
import '../models/filing_draft.dart';

/// Read/write access to claim filing drafts and progress tracking.
abstract class FilingRepository {
  /// Returns a (pre-filled) working draft for the given [lawsuitId].
  Future<FilingDraft> getDraft(String lawsuitId);

  /// Submits a completed [draft], starting its progress pipeline.
  Future<void> submit(FilingDraft draft);

  /// Lawsuit ids that have been submitted, for the "My Claims" list.
  Future<List<String>> submittedClaimIds();

  /// Stream of the claim's progress for the given [lawsuitId].
  Stream<ClaimProgress> watchProgress(String lawsuitId);
}
