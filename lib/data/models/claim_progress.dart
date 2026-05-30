/// Ordered stages a filed claim moves through.
enum ClaimStage { aiSubmitted, courtReview, settlementApproved, payoutSent }

/// Immutable tracker for a claim's current position in the pipeline.
class ClaimProgress {
  const ClaimProgress({required this.currentStage});

  final ClaimStage currentStage;

  /// Zero-based index of the current stage within [ClaimStage.values].
  int get stageIndex => ClaimStage.values.indexOf(currentStage);

  /// Returns progress at the next stage, capped at [ClaimStage.payoutSent].
  ClaimProgress advanced() {
    final next = stageIndex + 1;
    if (next >= ClaimStage.values.length) return this;
    return ClaimProgress(currentStage: ClaimStage.values[next]);
  }

  ClaimProgress copyWith({ClaimStage? currentStage}) {
    return ClaimProgress(currentStage: currentStage ?? this.currentStage);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimProgress &&
          runtimeType == other.runtimeType &&
          currentStage == other.currentStage;

  @override
  int get hashCode => currentStage.hashCode;
}
