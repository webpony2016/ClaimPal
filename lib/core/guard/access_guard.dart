import '../../data/models/user_account.dart';

/// The outcome of evaluating whether a user may file a claim.
enum FilingAccess {
  /// The user may proceed with filing.
  allow,

  /// The user is a guest and must register before filing.
  requireRegistration,

  /// The user is registered but out of autofill credit and must upgrade.
  requirePaywall,
}

/// Pure decision logic gating access to the filing flow.
///
/// - Guests must register first.
/// - Registered users with remaining autofill credit are allowed.
/// - Registered users out of credit hit the paywall.
FilingAccess resolveFilingAccess(UserAccount account) {
  if (account.isGuest) return FilingAccess.requireRegistration;
  if (account.hasAutofillCredit) return FilingAccess.allow;
  return FilingAccess.requirePaywall;
}
