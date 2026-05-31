import 'package:claimpal/data/models/fomo_summary.dart';
import 'package:claimpal/data/models/lawsuit.dart';
import 'package:claimpal/data/supabase/supabase_settlement_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 5, 30);

  test('maps an active settlement row into a Lawsuit model', () {
    final lawsuit = SupabaseSettlementMapper.toLawsuit(
      <String, dynamic>{
        'id': 'acme-1',
        'brand_name': 'Acme',
        'max_payout': 125,
        'deadline': '2026-06-12T00:00:00Z',
        'eligibility_text': 'Customers impacted by a data privacy incident.',
        'proof_required': true,
      },
      now: now,
    );

    expect(lawsuit.id, 'acme-1');
    expect(lawsuit.title, 'Acme Settlement');
    expect(lawsuit.status, LawsuitStatus.active);
    expect(lawsuit.category, LawsuitCategory.privacy);
    expect(lawsuit.payoutLabel, 'Up to');
    expect(lawsuit.payoutValue, '\$125');
    expect(lawsuit.expiredDaysAgo, isNull);
    expect(lawsuit.requiredProof, hasLength(2));
  });

  test('maps an expired settlement row with safe fallbacks', () {
    final lawsuit = SupabaseSettlementMapper.toLawsuit(
      <String, dynamic>{
        'id': 'old-1',
        'brand_name': 'Legacy Bank',
        'max_payout': null,
        'deadline': '2026-05-18T00:00:00Z',
        'eligibility_text': '',
        'proof_required': false,
      },
      now: now,
    );

    expect(lawsuit.status, LawsuitStatus.expired);
    expect(lawsuit.expiredDaysAgo, 12);
    expect(lawsuit.payoutLabel, 'Estimated');
    expect(lawsuit.payoutValue, 'TBD');
    expect(
      lawsuit.requiredProof.single,
      contains('No proof is listed right now'),
    );
    expect(
      lawsuit.eligibility,
      'Eligibility details will be published soon.',
    );
  });

  test('builds a six-month FOMO summary from settlement rows', () {
    final summary = SupabaseSettlementMapper.toFomoSummary(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'max_payout': 125,
          'deadline': '2026-05-10T00:00:00Z',
        },
        <String, dynamic>{
          'max_payout': 400,
          'deadline': '2025-10-01T00:00:00Z',
        },
        <String, dynamic>{
          'max_payout': 80,
          'deadline': '2026-06-05T00:00:00Z',
        },
        <String, dynamic>{
          'max_payout': 90,
          'deadline': '2026-07-15T00:00:00Z',
        },
        <String, dynamic>{
          'max_payout': null,
          'deadline': '2026-06-01T00:00:00Z',
        },
      ],
      now: now,
    );

    expect(summary.timeframe, FomoTimeframe.sixMonths);
    expect(summary.missedAmount, 125);
    expect(summary.upcomingAmount, 80);
  });
}