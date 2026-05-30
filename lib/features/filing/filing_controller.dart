import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/filing_draft.dart';
import '../../data/providers.dart';
import '../account/account_provider.dart';

/// Immutable state for the 3-step filing wizard.
class FilingState {
  const FilingState({
    required this.draft,
    required this.step,
    this.submitting = false,
  });

  /// The working draft, mutated as the user fills the wizard.
  final FilingDraft draft;

  /// Current wizard step index: 0 (review), 1 (declaration), 2 (success).
  final int step;

  /// Whether a [FilingController.submit] call is in flight.
  final bool submitting;

  FilingState copyWith({
    FilingDraft? draft,
    int? step,
    bool? submitting,
  }) {
    return FilingState(
      draft: draft ?? this.draft,
      step: step ?? this.step,
      submitting: submitting ?? this.submitting,
    );
  }
}

/// Drives a single lawsuit's filing wizard: loads the prefilled draft, tracks
/// the current step, and mutates the draft as the user supplies fields, a proof
/// file, and a signature. Keyed by lawsuit id.
class FilingController extends AsyncNotifier<FilingState> {
  FilingController(this.lawsuitId);

  /// The lawsuit id this controller manages (the family argument).
  final String lawsuitId;

  @override
  Future<FilingState> build() async {
    final draft =
        await ref.watch(filingRepositoryProvider).getDraft(lawsuitId);
    return FilingState(draft: draft, step: 0);
  }

  /// Returns the current loaded state, or `null` while loading / on error.
  FilingState? get _current => state.value;

  void _update(FilingState next) => state = AsyncData(next);

  /// Sets the value of an "Action Required" field by [key].
  void setActionField(String key, String? value) {
    final current = _current;
    if (current == null) return;
    final fields = Map<String, String?>.from(current.draft.actionRequiredFields)
      ..[key] = value;
    _update(current.copyWith(
      draft: current.draft.copyWith(actionRequiredFields: fields),
    ));
  }

  /// Records the (mock) uploaded proof file name.
  void setUploadedFile(String name) {
    final current = _current;
    if (current == null) return;
    _update(current.copyWith(
      draft: current.draft.copyWith(uploadedFileName: name),
    ));
  }

  /// Records the captured signature payload (non-empty when the user has drawn).
  void setSignature(String data) {
    final current = _current;
    if (current == null) return;
    _update(current.copyWith(
      draft: current.draft.copyWith(signatureData: data),
    ));
  }

  /// Clears any captured signature.
  void clearSignature() {
    final current = _current;
    if (current == null) return;
    _update(current.copyWith(
      draft: current.draft.copyWith(signatureData: ''),
    ));
  }

  /// Advances to the next wizard step (capped at the success step).
  void next() {
    final current = _current;
    if (current == null) return;
    if (current.step >= 2) return;
    _update(current.copyWith(step: current.step + 1));
  }

  /// Returns to the previous wizard step (floored at the first step).
  void back() {
    final current = _current;
    if (current == null) return;
    if (current.step <= 0) return;
    _update(current.copyWith(step: current.step - 1));
  }

  /// Submits the draft, consumes exactly one autofill credit, and advances to
  /// the success step. No-ops if already submitting or not loaded.
  Future<void> submit() async {
    final current = _current;
    if (current == null || current.submitting) return;

    // Flip `submitting` to true SYNCHRONOUSLY before the first await so the
    // "Authorize & Submit" button disables immediately on tap. Combined with
    // the early-return guard above, a synchronous double-tap re-enters here
    // after the flag is already set and bails out, so the credit is consumed
    // exactly once.
    _update(current.copyWith(submitting: true));
    try {
      await ref.read(filingRepositoryProvider).submit(current.draft);
      // Consume exactly one autofill credit per successful submit. (No-op for
      // unlimited/pro accounts.)
      ref.read(accountProvider.notifier).useAutofillCredit();
      _update(current.copyWith(submitting: false, step: 2));
    } catch (_) {
      _update(current.copyWith(submitting: false));
      rethrow;
    }
  }
}

/// Filing wizard controller, keyed by lawsuit id.
final filingControllerProvider =
    AsyncNotifierProvider.family<FilingController, FilingState, String>(
  FilingController.new,
);

/// Signature of the family factory `FilingController.new` above is
/// `FilingController Function(String)`, matching the family argument type.
