import 'package:claimpal/data/models/user_account.dart';
import 'package:claimpal/features/account/account_provider.dart';
import 'package:claimpal/features/filing/filing_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lawsuitId = 'facebook-data-privacy';

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  FilingController controller() =>
      container.read(filingControllerProvider(lawsuitId).notifier);

  Future<FilingState> loaded() =>
      container.read(filingControllerProvider(lawsuitId).future);

  test('loads a prefilled draft starting at step 0', () async {
    final state = await loaded();
    expect(state.step, 0);
    expect(state.draft.fullName, isNotEmpty);
    expect(state.draft.address, isNotEmpty);
    expect(state.draft.isStep1Complete, isFalse);
  });

  test('filling action field + upload completes step 1', () async {
    await loaded();
    controller().setActionField('Purchase Year', '2019');
    controller().setUploadedFile('receipt.pdf');

    final state = container.read(filingControllerProvider(lawsuitId)).value!;
    expect(state.draft.isStep1Complete, isTrue);
  });

  test('setSignature completes step 2', () async {
    await loaded();
    expect(
      container
          .read(filingControllerProvider(lawsuitId))
          .value!
          .draft
          .isStep2Complete,
      isFalse,
    );

    controller().setSignature('sig:42');
    final state = container.read(filingControllerProvider(lawsuitId)).value!;
    expect(state.draft.isStep2Complete, isTrue);

    controller().clearSignature();
    expect(
      container
          .read(filingControllerProvider(lawsuitId))
          .value!
          .draft
          .isStep2Complete,
      isFalse,
    );
  });

  test('next/back move between steps without leaving the success step', () async {
    await loaded();
    controller().next();
    expect(container.read(filingControllerProvider(lawsuitId)).value!.step, 1);
    controller().back();
    expect(container.read(filingControllerProvider(lawsuitId)).value!.step, 0);
    controller().back();
    expect(container.read(filingControllerProvider(lawsuitId)).value!.step, 0);
  });

  test('submit consumes exactly one autofill credit and advances to success',
      () async {
    await loaded();
    // Registered starter: limit 2, used 0.
    container.read(accountProvider.notifier).register();
    final usedBefore = container.read(accountProvider).autofillUsed;
    expect(container.read(accountProvider).tier, SubscriptionTier.starter);

    controller().setActionField('Purchase Year', '2019');
    controller().setUploadedFile('receipt.pdf');
    controller().setSignature('sig:10');

    await controller().submit();

    final usedAfter = container.read(accountProvider).autofillUsed;
    expect(usedAfter, usedBefore + 1);

    final state = container.read(filingControllerProvider(lawsuitId)).value!;
    expect(state.step, 2);
    expect(state.submitting, isFalse);
  });
}
