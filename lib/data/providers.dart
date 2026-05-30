import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock/mock_filing_repository.dart';
import 'mock/mock_lawsuit_repository.dart';
import 'mock/mock_referral_repository.dart';
import 'mock/mock_subscription_repository.dart';
import 'models/rewards_summary.dart';
import 'models/subscription_plan.dart';
import 'repositories/filing_repository.dart';
import 'repositories/lawsuit_repository.dart';
import 'repositories/referral_repository.dart';
import 'repositories/subscription_repository.dart';

/// Repository providers wire the mock implementations now; they can be
/// `override`n with Supabase-backed implementations later.

final lawsuitRepositoryProvider = Provider<LawsuitRepository>(
  (ref) => const MockLawsuitRepository(),
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => const MockSubscriptionRepository(),
);

final filingRepositoryProvider = Provider<FilingRepository>(
  (ref) => MockFilingRepository(),
);

final referralRepositoryProvider = Provider<ReferralRepository>(
  (ref) => const MockReferralRepository(),
);

/// Convenience data providers.

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).getPlans(),
);

final rewardsProvider = FutureProvider<RewardsSummary>(
  (ref) => ref.watch(referralRepositoryProvider).getRewards(),
);
