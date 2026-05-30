import 'package:claimpal/data/mock/mock_lawsuit_repository.dart';
import 'package:claimpal/data/models/lawsuit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repo = MockLawsuitRepository();

  test('watchActive emits only active lawsuits', () async {
    final list = await repo.watchActive().first;
    expect(list, isNotEmpty);
    expect(list.length, greaterThanOrEqualTo(6));
    expect(list.every((l) => l.status == LawsuitStatus.active), isTrue);
  });

  test('watchExpired emits only expired lawsuits', () async {
    final list = await repo.watchExpired().first;
    expect(list, isNotEmpty);
    expect(list.length, greaterThanOrEqualTo(3));
    expect(list.every((l) => l.status == LawsuitStatus.expired), isTrue);
  });

  test('getById returns the lawsuit on a hit', () async {
    final result = await repo.getById('facebook-data-privacy');
    expect(result, isNotNull);
    expect(result!.title, 'Facebook Data Privacy Settlement');
  });

  test('getById returns null on a miss', () async {
    final result = await repo.getById('does-not-exist');
    expect(result, isNull);
  });

  test('search is case-insensitive and finds Fitbit', () async {
    final result = await repo.search('fitbit');
    expect(result, isNotEmpty);
    expect(result.any((l) => l.title.contains('Fitbit')), isTrue);
  });

  test('getFomoSummary returns non-zero amounts', () async {
    final summary = await repo.getFomoSummary();
    expect(summary.missedAmount, greaterThan(0));
    expect(summary.upcomingAmount, greaterThan(0));
  });
}
