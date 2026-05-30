import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock/mock_lawsuit_repository.dart';
import 'repositories/lawsuit_repository.dart';

/// Repository providers wire the mock implementations now; they can be
/// `override`n with Supabase-backed implementations later.

final lawsuitRepositoryProvider = Provider<LawsuitRepository>(
  (ref) => const MockLawsuitRepository(),
);
