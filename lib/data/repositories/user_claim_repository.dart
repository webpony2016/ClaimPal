import '../models/user_claim.dart';

abstract class UserClaimRepository {
  Future<List<UserClaim>> getCurrentUserClaims();

  Stream<List<UserClaim>> watchCurrentUserClaims();

  Future<UserClaim?> getByLawsuitId(String lawsuitId);

  Future<void> markSelfIneligible(String lawsuitId);

  Future<void> clearSelfIneligible(String lawsuitId);

  Future<void> confirmPayout({
    required String lawsuitId,
    required double payoutAmount,
  });
}
