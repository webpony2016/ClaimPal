import '../models/fomo_summary.dart';
import '../models/lawsuit.dart';

/// Maps Supabase `settlements` rows into app-facing models.
class SupabaseSettlementMapper {
  const SupabaseSettlementMapper._();

  static Lawsuit toLawsuit(
    Map<String, dynamic> row, {
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now().toUtc();
    final brand = _readText(row['brand_name'], fallback: 'Unknown brand');
    final deadline = _readDateTime(row['deadline']);
    final payout = _readNum(row['max_payout']);
    final eligibility = _readText(
      row['eligibility_text'],
      fallback: 'Eligibility details will be published soon.',
    );
    final active = deadline == null || !deadline.isBefore(referenceNow);

    return Lawsuit(
      id: _readText(row['id'], fallback: brand.toLowerCase()),
      title: _buildTitle(brand),
      brand: brand,
      category: _inferCategory(brand: brand, eligibility: eligibility),
      status: active ? LawsuitStatus.active : LawsuitStatus.expired,
      payoutLabel: payout == null ? 'Estimated' : 'Up to',
      payoutValue: payout == null ? 'TBD' : _formatMoney(payout),
      deadline: deadline,
      expiredDaysAgo: active ? null : referenceNow.difference(deadline).inDays,
      eligibility: eligibility,
      requiredProof: _buildRequiredProof(row['proof_required'] == true),
    );
  }

  static FomoSummary toFomoSummary(
    Iterable<Map<String, dynamic>> rows, {
    DateTime? now,
    FomoTimeframe timeframe = FomoTimeframe.sixMonths,
  }) {
    final referenceNow = now ?? DateTime.now().toUtc();
    final missedCutoff = referenceNow.subtract(
      Duration(days: timeframe == FomoTimeframe.threeMonths ? 90 : 180),
    );
    final upcomingCutoff = referenceNow.add(const Duration(days: 30));

    var missedAmount = 0.0;
    var upcomingAmount = 0.0;

    for (final row in rows) {
      final payout = _readNum(row['max_payout']);
      final deadline = _readDateTime(row['deadline']);
      if (payout == null || deadline == null) {
        continue;
      }

      if (deadline.isBefore(referenceNow) && !deadline.isBefore(missedCutoff)) {
        missedAmount += payout;
      }

      final isUpcoming =
          !deadline.isBefore(referenceNow) && !deadline.isAfter(upcomingCutoff);
      if (isUpcoming) {
        upcomingAmount += payout;
      }
    }

    return FomoSummary(
      missedAmount: missedAmount,
      upcomingAmount: upcomingAmount,
      timeframe: timeframe,
    );
  }

  static LawsuitCategory _inferCategory({
    required String brand,
    required String eligibility,
  }) {
    final haystack = '${brand.toLowerCase()} ${eligibility.toLowerCase()}';

    if (haystack.contains('breach') || haystack.contains('security')) {
      return LawsuitCategory.security;
    }
    if (haystack.contains('privacy') ||
        haystack.contains('data') ||
        haystack.contains('biometric')) {
      return LawsuitCategory.privacy;
    }
    if (haystack.contains('bank') ||
        haystack.contains('credit') ||
        haystack.contains('finance') ||
        haystack.contains('payment') ||
        haystack.contains('loan') ||
        haystack.contains('plaid')) {
      return LawsuitCategory.finance;
    }
    if (haystack.contains('health') ||
        haystack.contains('medical') ||
        haystack.contains('pharma') ||
        haystack.contains('fitbit') ||
        haystack.contains('wellness')) {
      return LawsuitCategory.health;
    }
    return LawsuitCategory.other;
  }

  static String _buildTitle(String brand) {
    final normalized = brand.toLowerCase();
    if (normalized.contains('settlement') || normalized.contains('class action')) {
      return brand;
    }
    return '$brand Settlement';
  }

  static List<String> _buildRequiredProof(bool proofRequired) {
    if (proofRequired) {
      return const <String>[
        'Proof of purchase, account ownership, or participation may be required.',
        'Keep receipts, account emails, or other supporting records handy.',
      ];
    }

    return const <String>[
      'No proof is listed right now; basic contact details may still be requested.',
    ];
  }

  static DateTime? _readDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  static double? _readNum(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String _readText(Object? value, {required String fallback}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String _formatMoney(double value) {
    final whole = value.truncateToDouble() == value;
    return whole ? '\$${value.toStringAsFixed(0)}' : '\$${value.toStringAsFixed(2)}';
  }
}