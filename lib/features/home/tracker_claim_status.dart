import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/claim_progress.dart';
import '../../data/models/user_claim.dart';
import '../../data/providers.dart';

/// The user-specific status of a lawsuit as surfaced on the Tracker home.
///
/// This is an overlay on top of the catalog [Lawsuit] data: it captures what
/// the *current user* has done with a settlement, independent of whether the
/// settlement window itself is still open.
enum TrackerClaimStatus {
  /// The user has not interacted with this lawsuit.
  none,

  /// The user filed a claim and it is moving through the pipeline.
  filed,

  /// The user filed a claim and the payout has been received.
  paid,

  /// The user reviewed eligibility and marked themselves as not qualifying.
  /// Rendered like an expired card, but still editable.
  ineligible,
}

/// A single user overlay entry for a lawsuit.
class TrackerClaimEntry {
  const TrackerClaimEntry(this.status, {this.stage, this.payoutAmount = 0});

  final TrackerClaimStatus status;

  /// Pipeline stage to show for [TrackerClaimStatus.filed] /
  /// [TrackerClaimStatus.paid]. Ignored for the other statuses.
  final ClaimStage? stage;

  /// Real payout amount received for [TrackerClaimStatus.paid].
  final double payoutAmount;

  TrackerClaimEntry copyWith({
    TrackerClaimStatus? status,
    ClaimStage? stage,
    double? payoutAmount,
  }) {
    return TrackerClaimEntry(
      status ?? this.status,
      stage: stage ?? this.stage,
      payoutAmount: payoutAmount ?? this.payoutAmount,
    );
  }
}

const Map<String, TrackerClaimEntry> _mockTrackerClaimOverlay =
    <String, TrackerClaimEntry>{
  'capital-one-breach': TrackerClaimEntry(
    TrackerClaimStatus.paid,
    stage: ClaimStage.payoutSent,
    payoutAmount: 25,
  ),
  'fitbit-heart-rate': TrackerClaimEntry(
    TrackerClaimStatus.filed,
    stage: ClaimStage.courtReview,
  ),
  'tmobile-data-breach': TrackerClaimEntry(
    TrackerClaimStatus.ineligible,
  ),
};

/// Current received-payout total across all paid claims.
final trackerPayoutTotalProvider = Provider<double>((ref) {
  final overlay = ref.watch(trackerClaimStatusProvider);
  return overlay.values
      .where((entry) => entry.status == TrackerClaimStatus.paid)
      .fold<double>(0, (sum, entry) => sum + entry.payoutAmount);
});

/// The current per-lawsuit user overlay.
final trackerClaimStatusProvider = Provider<Map<String, TrackerClaimEntry>>(
  (ref) {
    if (!ref.watch(useSupabaseDataProvider)) {
      return _mockTrackerClaimOverlay;
    }

    final claims = ref.watch(userClaimsProvider).maybeWhen(
      data: (value) => value,
      orElse: () => const <UserClaim>[],
    );

    final overlay = <String, TrackerClaimEntry>{};
    for (final claim in claims) {
      final entry = _entryForClaim(claim);
      if (entry != null) {
        overlay[claim.lawsuitId] = entry;
      }
    }
    return overlay;
  },
);

TrackerClaimEntry? _entryForClaim(UserClaim claim) {
  if (claim.isSelfIneligible) {
    return const TrackerClaimEntry(TrackerClaimStatus.ineligible);
  }

  if (claim.isPaid) {
    return TrackerClaimEntry(
      TrackerClaimStatus.paid,
      stage: claim.currentStage ?? ClaimStage.payoutSent,
      payoutAmount: claim.confirmedPayoutAmount,
    );
  }

  if (claim.isSubmittedClaim) {
    return TrackerClaimEntry(
      TrackerClaimStatus.filed,
      stage: claim.currentStage ?? ClaimStage.aiSubmitted,
    );
  }

  return null;
}

/// Resolves the effective [TrackerClaimStatus] for a lawsuit by combining the
/// user overlay with the session's submitted-claim ids.
///
/// Precedence: ineligible > paid > filed > none. A submitted id with no overlay
/// entry is treated as a freshly filed (in-progress) claim.
TrackerClaimStatus resolveTrackerStatus({
  required String lawsuitId,
  required Map<String, TrackerClaimEntry> overlay,
  required Set<String> submittedIds,
}) {
  final entry = overlay[lawsuitId];
  if (entry?.status == TrackerClaimStatus.ineligible) {
    return TrackerClaimStatus.ineligible;
  }
  if (entry?.status == TrackerClaimStatus.paid ||
      entry?.stage == ClaimStage.payoutSent) {
    return TrackerClaimStatus.paid;
  }
  if (entry?.status == TrackerClaimStatus.filed ||
      submittedIds.contains(lawsuitId)) {
    return TrackerClaimStatus.filed;
  }
  return TrackerClaimStatus.none;
}
