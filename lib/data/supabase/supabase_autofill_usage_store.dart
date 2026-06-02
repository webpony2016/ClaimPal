import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/autofill_usage_snapshot.dart';
import 'supabase_autofill_usage_mapper.dart';

/// Reads and atomically consumes persisted AI autofill credits via Supabase RPC.
class SupabaseAutofillUsageStore {
  SupabaseAutofillUsageStore(this._client);

  final SupabaseClient _client;

  Future<AutofillUsageSnapshot> getCurrentUsage() async {
    final response = await _client.rpc('get_current_autofill_usage');
    return SupabaseAutofillUsageMapper.toSnapshot(_firstRow(response));
  }

  Future<AutofillUsageSnapshot> consumeCredit() async {
    final response = await _client.rpc('consume_autofill_credit');
    return SupabaseAutofillUsageMapper.toSnapshot(_firstRow(response));
  }

  static Map<String, dynamic> _firstRow(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    throw StateError('Unexpected autofill usage RPC payload.');
  }
}