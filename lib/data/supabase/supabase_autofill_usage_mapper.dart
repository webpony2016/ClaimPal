import '../models/autofill_usage_snapshot.dart';
import '../models/user_account.dart';

/// Maps autofill usage RPC payloads into Dart models.
class SupabaseAutofillUsageMapper {
  const SupabaseAutofillUsageMapper._();

  static AutofillUsageSnapshot toSnapshot(Map<String, dynamic> row) {
    return AutofillUsageSnapshot(
      effectiveTier: _parseTier(row['effective_tier']?.toString()),
      autofillLimit: _parseNullableInt(row['autofill_limit']),
      usedCount: _parseInt(row['used_count']),
      scope: row['scope']?.toString() ?? 'starter_lifetime',
      periodStart: _parseDate(row['period_start']),
    );
  }

  static SubscriptionTier _parseTier(String? value) {
    switch (value) {
      case 'plus':
        return SubscriptionTier.plus;
      case 'pro':
        return SubscriptionTier.pro;
      case 'starter':
      default:
        return SubscriptionTier.starter;
    }
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  static int? _parseNullableInt(Object? value) {
    if (value == null) return null;
    return _parseInt(value);
  }

  static DateTime _parseDate(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw StateError('Invalid period_start in autofill usage payload.');
    }
    return parsed.toUtc();
  }
}