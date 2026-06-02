import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/claimpal_environment.dart';
import 'mock/mock_filing_repository.dart';
import 'mock/mock_lawsuit_repository.dart';
import 'mock/mock_referral_repository.dart';
import 'mock/mock_subscription_repository.dart';
import 'models/claim_progress.dart';
import 'models/fomo_summary.dart';
import 'models/lawsuit.dart';
import 'models/rewards_summary.dart';
import 'models/subscription_plan.dart';
import 'models/user_claim.dart';
import 'repositories/filing_repository.dart';
import 'repositories/lawsuit_repository.dart';
import 'repositories/referral_repository.dart';
import 'repositories/subscription_repository.dart';
import 'repositories/user_claim_repository.dart';
import 'supabase/supabase_autofill_usage_store.dart';
import 'supabase/supabase_filing_repository.dart';
import 'supabase/supabase_lawsuit_repository.dart';
import 'supabase/supabase_referral_repository.dart';
import 'supabase/supabase_user_claim_repository.dart';

/// Repository providers wire the mock implementations now; they can be
/// `override`n with Supabase-backed implementations later.

final useSupabaseDataProvider = Provider<bool>(
  (ref) => ClaimPalEnvironment.hasSupabaseConfig,
);

final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => ref.watch(useSupabaseDataProvider)
      ? Supabase.instance.client
      : null,
);

final supabaseAutofillUsageStoreProvider = Provider<SupabaseAutofillUsageStore?>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    return client == null ? null : SupabaseAutofillUsageStore(client);
  },
);

final lawsuitRepositoryProvider = Provider<LawsuitRepository>(
  (ref) {
    if (ref.watch(useSupabaseDataProvider)) {
      return SupabaseLawsuitRepository(Supabase.instance.client);
    }
    return const MockLawsuitRepository();
  },
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => const MockSubscriptionRepository(),
);

final filingRepositoryProvider = Provider<FilingRepository>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    if (client != null) {
      return SupabaseFilingRepository(client);
    }
    return MockFilingRepository();
  },
);

final userClaimRepositoryProvider = Provider<UserClaimRepository?>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    return client == null ? null : SupabaseUserClaimRepository(client);
  },
);

final referralRepositoryProvider = Provider<ReferralRepository>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);
    if (client != null) {
      return SupabaseReferralRepository(client);
    }
    return const MockReferralRepository();
  },
);

/// Convenience data providers.

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).getPlans(),
);

final rewardsProvider = FutureProvider<RewardsSummary>(
  (ref) => ref.watch(referralRepositoryProvider).getRewards(),
);

/// Loads a single lawsuit by id (or `null` if none matches). Used by the
/// lawsuit detail screen.
final lawsuitByIdProvider = FutureProvider.family<Lawsuit?, String>(
  (ref, id) => ref.watch(lawsuitRepositoryProvider).getById(id),
);

/// Streams the active (claimable) lawsuits.
final activeLawsuitsProvider = StreamProvider<List<Lawsuit>>(
  (ref) => ref.watch(lawsuitRepositoryProvider).watchActive(),
);

/// Streams the expired (closed) lawsuits.
final expiredLawsuitsProvider = StreamProvider<List<Lawsuit>>(
  (ref) => ref.watch(lawsuitRepositoryProvider).watchExpired(),
);

/// Loads the FOMO summary (missed / upcoming payouts) for the home banner.
final fomoSummaryProvider = FutureProvider<FomoSummary>(
  (ref) => ref.watch(lawsuitRepositoryProvider).getFomoSummary(),
);

/// Streams the current authenticated user's real claim snapshots.
final userClaimsProvider = StreamProvider<List<UserClaim>>(
  (ref) {
    final repository = ref.watch(userClaimRepositoryProvider);
    return repository?.watchCurrentUserClaims() ??
        Stream.value(const <UserClaim>[]);
  },
);

/// Streams the [ClaimProgress] pipeline for a filed claim, keyed by lawsuit id.
/// Used by the filing success screen's [ClaimStepper].
final claimProgressProvider = StreamProvider.family<ClaimProgress, String>(
  (ref, id) => ref.watch(filingRepositoryProvider).watchProgress(id),
);

/// Loads the lawsuit ids the user has submitted, for the My Claims screen.
final submittedClaimIdsProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(filingRepositoryProvider).submittedClaimIds(),
);
