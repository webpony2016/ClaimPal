import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock/mock_lawsuit_repository.dart';
import 'mock/mock_subscription_repository.dart';
import 'models/subscription_plan.dart';
import 'repositories/lawsuit_repository.dart';
import 'repositories/subscription_repository.dart';

/// Repository providers wire the mock implementations now; they can be
/// `override`n with Supabase-backed implementations later.

final lawsuitRepositoryProvider = Provider<LawsuitRepository>(
  (ref) => const MockLawsuitRepository(),
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => const MockSubscriptionRepository(),
);

/// Convenience data providers.

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).getPlans(),
);
