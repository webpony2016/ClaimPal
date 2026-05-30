import '../models/subscription_plan.dart';
import '../models/user_account.dart' show SubscriptionTier;
import '../repositories/subscription_repository.dart';
import 'mock_data.dart';

/// In-memory [SubscriptionRepository] returning the three fixed plans.
class MockSubscriptionRepository implements SubscriptionRepository {
  const MockSubscriptionRepository();

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    await Future<void>.delayed(kMockLatency);
    if (kMockSimulateFailure) {
      throw StateError('Mock failure: getPlans');
    }
    return const [
      SubscriptionPlan(
        tier: SubscriptionTier.starter,
        monthlyPrice: 0,
        yearlyPrice: 0,
        monthlyAutofills: 2,
        features: [
          '2 AI autofills per month',
          'Browse active settlements',
          'Manual claim filing',
        ],
      ),
      SubscriptionPlan(
        tier: SubscriptionTier.plus,
        monthlyPrice: 2.99,
        yearlyPrice: 19.99,
        monthlyAutofills: 5,
        features: [
          '5 AI autofills per month',
          'Priority claim processing',
          'Referral rewards',
        ],
      ),
      SubscriptionPlan(
        tier: SubscriptionTier.pro,
        monthlyPrice: 5.99,
        yearlyPrice: 39.99,
        monthlyAutofills: null,
        features: [
          'Unlimited AI autofills',
          'Priority claim processing',
          'Early access to new settlements',
        ],
      ),
    ];
  }
}
