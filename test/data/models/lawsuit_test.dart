import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/data/models/lawsuit.dart';

Lawsuit _active() => Lawsuit(
      id: 'l1',
      title: 'Data Breach Settlement',
      brand: 'Acme',
      category: LawsuitCategory.privacy,
      status: LawsuitStatus.active,
      payoutLabel: 'Up to',
      payoutValue: '\$250',
      deadline: DateTime(2026, 12, 31),
      expiredDaysAgo: null,
      eligibility: 'Customers since 2020',
      requiredProof: const ['email', 'receipt'],
    );

void main() {
  test('active and expired instances differ', () {
    final active = _active();
    final expired = Lawsuit(
      id: 'l2',
      title: 'Old Claim',
      brand: 'Beta',
      category: LawsuitCategory.finance,
      status: LawsuitStatus.expired,
      payoutLabel: 'Fixed',
      payoutValue: '\$50',
      deadline: null,
      expiredDaysAgo: 12,
      eligibility: 'Any user',
      requiredProof: const ['statement'],
    );
    expect(active.status, LawsuitStatus.active);
    expect(expired.status, LawsuitStatus.expired);
    expect(expired.expiredDaysAgo, 12);
    expect(active, isNot(equals(expired)));
  });

  test('list equality and value equality', () {
    final a = _active();
    final b = _active();
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));

    final diffList = a.copyWith(requiredProof: const ['email']);
    expect(diffList, isNot(equals(a)));
  });

  test('copyWith(status:) updates status only', () {
    final a = _active();
    final closed = a.copyWith(status: LawsuitStatus.expired);
    expect(closed.status, LawsuitStatus.expired);
    expect(closed.id, a.id);
    expect(closed.requiredProof, a.requiredProof);
  });
}
