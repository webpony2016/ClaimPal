import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fomo_summary.dart';
import '../models/lawsuit.dart';
import '../repositories/lawsuit_repository.dart';
import 'supabase_settlement_mapper.dart';

/// Read-only [LawsuitRepository] backed by Supabase `public.settlements`.
class SupabaseLawsuitRepository implements LawsuitRepository {
  SupabaseLawsuitRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'settlements';
  static const String _selectColumns =
      'id, brand_name, max_payout, deadline, eligibility_text, proof_required';

  @override
  Stream<List<Lawsuit>> watchActive() async* {
    final lawsuits = await _fetchAll();
    yield lawsuits.where((item) => item.status == LawsuitStatus.active).toList();
  }

  @override
  Stream<List<Lawsuit>> watchExpired() async* {
    final lawsuits = await _fetchAll();
    yield lawsuits.where((item) => item.status == LawsuitStatus.expired).toList();
  }

  @override
  Future<Lawsuit?> getById(String id) async {
    final row = await _client
        .from(_table)
        .select(_selectColumns)
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      return null;
    }

    return SupabaseSettlementMapper.toLawsuit(_normalizeRow(row));
  }

  @override
  Future<FomoSummary> getFomoSummary() async {
    final rows = await _selectRows();
    return SupabaseSettlementMapper.toFomoSummary(rows);
  }

  @override
  Future<List<Lawsuit>> search(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const <Lawsuit>[];
    }

    final lawsuits = await _fetchAll();
    return lawsuits.where((lawsuit) {
      return lawsuit.title.toLowerCase().contains(normalizedQuery) ||
          lawsuit.brand.toLowerCase().contains(normalizedQuery) ||
          lawsuit.eligibility.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  Future<List<Lawsuit>> _fetchAll() async {
    final rows = await _selectRows();
    final lawsuits = rows.map(SupabaseSettlementMapper.toLawsuit).toList();
    lawsuits.sort(_compareLawsuits);
    return lawsuits;
  }

  Future<List<Map<String, dynamic>>> _selectRows() async {
    final response = await _client
        .from(_table)
        .select(_selectColumns)
        .order('deadline', ascending: true);
    return response
        .cast<Map<String, dynamic>>()
        .map(_normalizeRow)
        .toList(growable: false);
  }

  static Map<String, dynamic> _normalizeRow(Map<String, dynamic> row) {
    return Map<String, dynamic>.from(row);
  }

  static int _compareLawsuits(Lawsuit a, Lawsuit b) {
    if (a.status != b.status) {
      return a.status == LawsuitStatus.active ? -1 : 1;
    }

    final leftDeadline = a.deadline;
    final rightDeadline = b.deadline;
    if (leftDeadline == null && rightDeadline == null) {
      return a.title.compareTo(b.title);
    }
    if (leftDeadline == null) return 1;
    if (rightDeadline == null) return -1;

    if (a.status == LawsuitStatus.expired) {
      return rightDeadline.compareTo(leftDeadline);
    }
    return leftDeadline.compareTo(rightDeadline);
  }
}