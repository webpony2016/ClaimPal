import 'package:claimpal/core/theme/app_theme.dart';
import 'package:claimpal/data/models/lawsuit.dart';
import 'package:claimpal/features/account/account_provider.dart';
import 'package:claimpal/features/filing/start_filing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/google_fonts_test_setup.dart';

const _lawsuit = Lawsuit(
  id: 'tmobile-data-breach',
  title: 'T-Mobile Data Breach Settlement',
  brand: 'T-Mobile',
  category: LawsuitCategory.security,
  status: LawsuitStatus.active,
  payoutLabel: 'Up to',
  payoutValue: '\$250',
  deadline: null,
  expiredDaysAgo: null,
  eligibility: 'You were a T-Mobile customer.',
  requiredProof: <String>['Account phone number'],
);

/// A button that triggers [startFiling] for [_lawsuit] on tap.
class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ElevatedButton(
        onPressed: () => startFiling(context, ref, _lawsuit),
        child: const Text('Start'),
      ),
    );
  }
}

GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (context, state) => const _Harness()),
        GoRoute(
          path: '/filing/:id',
          builder: (_, state) =>
              Text('FILING ${state.pathParameters['id']}'),
        ),
      ],
    );

Widget _app(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: buildTheme(),
      routerConfig: _router(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupGoogleFontsForTesting();

  testWidgets('guest tapping File Claim sees the registration sheet',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    // Registration sheet heading is present.
    expect(find.text('Create an account to file'), findsOneWidget);
  });

  testWidgets('credit-exhausted starter sees the paywall with a plan price',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Register (guest -> starter) then exhaust both starter credits.
    final notifier = container.read(accountProvider.notifier)..register();
    await notifier.useAutofillCredit();
    await notifier.useAutofillCredit();

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    // Open the sheet, then let the plans future resolve (mock latency 300ms).
    // We cannot pumpAndSettle while the loading spinner animates indefinitely.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump();

    // Paywall plan card and price (Plus monthly) are shown.
    expect(find.text('Plus Plan'), findsOneWidget);
    expect(find.text('\$2.99'), findsOneWidget);
    // Referral copy says "1 month of Plus".
    expect(
      find.text('Or invite friends to unlock 1 month of Plus free'),
      findsOneWidget,
    );
  });

  testWidgets('registered user with credit goes straight to filing',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(accountProvider.notifier).register();

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('FILING tmobile-data-breach'), findsOneWidget);
  });
}
