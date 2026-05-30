import 'package:claimpal/data/models/user_account.dart';
import 'package:claimpal/features/account/account_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  UserAccount read() => container.read(accountProvider);
  AccountNotifier notifier() => container.read(accountProvider.notifier);

  test('initial state is a guest with limit 2', () {
    final state = read();
    expect(state.isGuest, isTrue);
    expect(state.autofillLimit, 2);
  });

  test('register sets isGuest false, stays starter, limit 2, used 0', () {
    notifier().register();
    final state = read();
    expect(state.isGuest, isFalse);
    expect(state.tier, SubscriptionTier.starter);
    expect(state.autofillLimit, 2);
    expect(state.autofillUsed, 0);
  });

  test('useAutofillCredit twice exhausts starter credit', () {
    notifier().register();
    notifier().useAutofillCredit();
    notifier().useAutofillCredit();
    final state = read();
    expect(state.autofillUsed, 2);
    expect(state.hasAutofillCredit, isFalse);
  });

  test('upgradeTo(pro) sets unlimited (null) limit and resets usage', () {
    notifier().register();
    notifier().useAutofillCredit();
    notifier().upgradeTo(SubscriptionTier.pro);
    final state = read();
    expect(state.tier, SubscriptionTier.pro);
    expect(state.autofillLimit, isNull);
    expect(state.autofillUsed, 0);
    expect(state.hasAutofillCredit, isTrue);
  });

  test('pro useAutofillCredit keeps unlimited credit', () {
    notifier().upgradeTo(SubscriptionTier.pro);
    notifier().useAutofillCredit();
    notifier().useAutofillCredit();
    final state = read();
    expect(state.autofillLimit, isNull);
    expect(state.autofillUsed, 0); // unlimited: no-op
    expect(state.hasAutofillCredit, isTrue);
  });

  test('upgradeTo(plus) sets limit 5', () {
    notifier().upgradeTo(SubscriptionTier.plus);
    final state = read();
    expect(state.tier, SubscriptionTier.plus);
    expect(state.autofillLimit, 5);
    expect(state.autofillUsed, 0);
  });
}
