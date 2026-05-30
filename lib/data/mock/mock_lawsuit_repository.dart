import '../models/fomo_summary.dart';
import '../models/lawsuit.dart';
import '../repositories/lawsuit_repository.dart';
import 'mock_data.dart';

/// In-memory [LawsuitRepository] backed by the seed data in [mock_data.dart].
class MockLawsuitRepository implements LawsuitRepository {
  const MockLawsuitRepository();

  @override
  Stream<List<Lawsuit>> watchActive() {
    if (kMockSimulateFailure) {
      return Stream.error(StateError('Mock failure: watchActive'));
    }
    return Stream.value(List<Lawsuit>.from(kMockActiveLawsuits));
  }

  @override
  Stream<List<Lawsuit>> watchExpired() {
    if (kMockSimulateFailure) {
      return Stream.error(StateError('Mock failure: watchExpired'));
    }
    return Stream.value(List<Lawsuit>.from(kMockExpiredLawsuits));
  }

  @override
  Future<Lawsuit?> getById(String id) async {
    await Future<void>.delayed(kMockLatency);
    if (kMockSimulateFailure) {
      throw StateError('Mock failure: getById');
    }
    for (final lawsuit in [...kMockActiveLawsuits, ...kMockExpiredLawsuits]) {
      if (lawsuit.id == id) return lawsuit;
    }
    return null;
  }

  @override
  Future<FomoSummary> getFomoSummary() async {
    await Future<void>.delayed(kMockLatency);
    if (kMockSimulateFailure) {
      throw StateError('Mock failure: getFomoSummary');
    }
    return kMockFomoSummary;
  }

  @override
  Future<List<Lawsuit>> search(String query) async {
    await Future<void>.delayed(kMockLatency);
    if (kMockSimulateFailure) {
      throw StateError('Mock failure: search');
    }
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return [...kMockActiveLawsuits, ...kMockExpiredLawsuits].where((l) {
      return l.title.toLowerCase().contains(q) ||
          l.brand.toLowerCase().contains(q);
    }).toList();
  }
}
