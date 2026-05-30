import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/core/guard/access_guard.dart';
import 'package:claimpal/data/models/user_account.dart';

void main() {
  test('guest filing -> requireRegistration', () {
    expect(
      resolveFilingAccess(const UserAccount.guest()),
      FilingAccess.requireRegistration,
    );
  });
  test('free user with credit -> allow', () {
    expect(
      resolveFilingAccess(
        const UserAccount(
          isGuest: false,
          tier: SubscriptionTier.starter,
          autofillUsed: 1,
          autofillLimit: 2,
        ),
      ),
      FilingAccess.allow,
    );
  });
  test('free user out of credit -> requirePaywall', () {
    expect(
      resolveFilingAccess(
        const UserAccount(
          isGuest: false,
          tier: SubscriptionTier.starter,
          autofillUsed: 2,
          autofillLimit: 2,
        ),
      ),
      FilingAccess.requirePaywall,
    );
  });
  test('pro -> allow', () {
    expect(
      resolveFilingAccess(
        const UserAccount(
          isGuest: false,
          tier: SubscriptionTier.pro,
          autofillUsed: 99,
          autofillLimit: null,
        ),
      ),
      FilingAccess.allow,
    );
  });
}
