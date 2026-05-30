import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/guard/access_guard.dart';
import '../../data/models/lawsuit.dart';
import '../account/account_provider.dart';
import '../auth/registration_sheet.dart';
import '../pricing/paywall_sheet.dart';

/// Entry point for the "File Claim" action across home and detail screens.
///
/// Resolves the user's filing access and either proceeds straight to the
/// filing flow, or presents the registration / paywall half-sheet first. Those
/// sheets are responsible for navigating onward after a successful
/// registration or upgrade, so this helper simply routes to the right gate.
Future<void> startFiling(
  BuildContext context,
  WidgetRef ref,
  Lawsuit lawsuit,
) async {
  final access = resolveFilingAccess(ref.read(accountProvider));
  switch (access) {
    case FilingAccess.allow:
      context.go('/filing/${lawsuit.id}');
    case FilingAccess.requireRegistration:
      await showRegistrationSheet(context, ref, lawsuit);
    case FilingAccess.requirePaywall:
      await showPaywallSheet(context, ref, lawsuit);
  }
}
