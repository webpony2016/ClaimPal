import '../models/subscription_plan.dart';

/// Read access to the purchasable subscription plans.
abstract class SubscriptionRepository {
  /// Returns the available plans (starter, plus, pro).
  Future<List<SubscriptionPlan>> getPlans();
}
