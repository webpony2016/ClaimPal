import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/data/models/fomo_summary.dart';

void main() {
  test('copyWith changes fields', () {
    const s = FomoSummary(
      missedAmount: 120.5,
      upcomingAmount: 80.0,
      timeframe: FomoTimeframe.threeMonths,
    );
    final updated = s.copyWith(timeframe: FomoTimeframe.sixMonths);
    expect(updated.timeframe, FomoTimeframe.sixMonths);
    expect(updated.missedAmount, 120.5);
    expect(updated.upcomingAmount, 80.0);
  });

  test('equality and hashCode', () {
    const a = FomoSummary(
      missedAmount: 10,
      upcomingAmount: 20,
      timeframe: FomoTimeframe.threeMonths,
    );
    const b = FomoSummary(
      missedAmount: 10,
      upcomingAmount: 20,
      timeframe: FomoTimeframe.threeMonths,
    );
    const c = FomoSummary(
      missedAmount: 10,
      upcomingAmount: 21,
      timeframe: FomoTimeframe.threeMonths,
    );
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });
}
