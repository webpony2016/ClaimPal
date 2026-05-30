import 'package:claimpal/data/models/claim_progress.dart';
import 'package:claimpal/data/models/filing_draft.dart';
import 'package:claimpal/data/models/user_account.dart';
import 'package:claimpal/data/providers.dart';
import 'package:claimpal/data/repositories/filing_repository.dart';
import 'package:claimpal/features/account/account_provider.dart';
import 'package:claimpal/features/filing/filing_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads a normal prefilled draft but fails on [submit], so we can exercise the
/// controller's error path without flipping the global `kMockSimulateFailure`
/// (a compile-time `const`).
class _SubmitFailsRepository implements FilingRepository {
  @override
  Future<FilingDraft> getDraft(String lawsuitId) async {
    return FilingDraft(
      lawsuitId: lawsuitId,
      fullName: 'Jordan Smith',
      address: '123 Market St, San Francisco, CA',
      actionRequiredFields: const {'Purchase Year': null},
      uploadedFileName: null,
      signatureData: null,
    );
  }

  @override
  Future<void> submit(FilingDraft draft) async {
    throw StateError('submit failed');
  }

  @override
  Future<List<String>> submittedClaimIds() async => <String>[];

  @override
  Stream<ClaimProgress> watchProgress(String lawsuitId) =>
      Stream.value(const ClaimProgress(currentStage: ClaimStage.aiSubmitted));
}

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

  test('double-submit (fire two, await once) consumes exactly one credit',
      () async {
    await loaded();
    container.read(accountProvider.notifier).register();
    final usedBefore = container.read(accountProvider).autofillUsed;

    controller().setActionField('Purchase Year', '2019');
    controller().setUploadedFile('receipt.pdf');
    controller().setSignature('sig:10');

    // Fire the first submit (sets `submitting` synchronously) then immediately
    // fire a second; the re-entrancy guard must drop the second call.
    final first = controller().submit();
    final second = controller().submit();
    await Future.wait(<Future<void>>[first, second]);

    expect(container.read(accountProvider).autofillUsed, usedBefore + 1);
    final state = container.read(filingControllerProvider(lawsuitId)).value!;
    expect(state.step, 2);
    expect(state.submitting, isFalse);
  });

  test('submit error leaves credit unchanged and resets submitting', () async {
    final errContainer = ProviderContainer(
      overrides: [
        filingRepositoryProvider.overrideWithValue(_SubmitFailsRepository()),
      ],
    );
    addTearDown(errContainer.dispose);

    await errContainer.read(filingControllerProvider(lawsuitId).future);
    errContainer.read(accountProvider.notifier).register();
    final usedBefore = errContainer.read(accountProvider).autofillUsed;

    final ctrl =
        errContainer.read(filingControllerProvider(lawsuitId).notifier);
    ctrl.setActionField('Purchase Year', '2019');
    ctrl.setUploadedFile('receipt.pdf');
    ctrl.setSignature('sig:10');

    await expectLater(ctrl.submit(), throwsStateError);

    // No credit consumed, no permanent lock, and still on the signature step.
    expect(errContainer.read(accountProvider).autofillUsed, usedBefore);
    final state =
        errContainer.read(filingControllerProvider(lawsuitId)).value!;
    expect(state.submitting, isFalse);
    expect(state.step, isNot(2));
  });
}
