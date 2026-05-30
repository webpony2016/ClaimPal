import '../models/fomo_summary.dart';
import '../models/lawsuit.dart';

/// Read access to class-action lawsuits and the FOMO summary.
///
/// Pure Dart interface (no Flutter imports) so it can be backed by a mock now
/// and a Supabase-backed implementation later via provider override.
abstract class LawsuitRepository {
  /// Stream of currently active (claimable) lawsuits.
  Stream<List<Lawsuit>> watchActive();

  /// Stream of expired (closed) lawsuits.
  Stream<List<Lawsuit>> watchExpired();

  /// Returns the lawsuit with [id], or `null` if none matches.
  Future<Lawsuit?> getById(String id);

  /// Returns the missed/upcoming payout summary used for the FOMO banner.
  Future<FomoSummary> getFomoSummary();

  /// Case-insensitive substring search over title and brand.
  Future<List<Lawsuit>> search(String query);
}
