/// Timeframe over which missed/upcoming payouts are summarized.
enum FomoTimeframe { threeMonths, sixMonths }

/// Immutable summary of missed and upcoming payout amounts over a timeframe.
class FomoSummary {
  const FomoSummary({
    required this.missedAmount,
    required this.upcomingAmount,
    required this.timeframe,
  });

  final double missedAmount;
  final double upcomingAmount;
  final FomoTimeframe timeframe;

  FomoSummary copyWith({
    double? missedAmount,
    double? upcomingAmount,
    FomoTimeframe? timeframe,
  }) {
    return FomoSummary(
      missedAmount: missedAmount ?? this.missedAmount,
      upcomingAmount: upcomingAmount ?? this.upcomingAmount,
      timeframe: timeframe ?? this.timeframe,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FomoSummary &&
          runtimeType == other.runtimeType &&
          missedAmount == other.missedAmount &&
          upcomingAmount == other.upcomingAmount &&
          timeframe == other.timeframe;

  @override
  int get hashCode => Object.hash(missedAmount, upcomingAmount, timeframe);
}
