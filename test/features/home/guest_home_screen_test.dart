import 'package:claimpal/core/router/app_router.dart';
import 'package:claimpal/core/theme/app_theme.dart';
import 'package:claimpal/data/providers.dart';
import 'package:claimpal/features/account/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/google_fonts_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupGoogleFontsForTesting();

  Widget app() => ProviderScope(
        child: MaterialApp.router(
          theme: buildTheme(),
          routerConfig: buildRouter(),
        ),
      );

  testWidgets('shows expired lawsuits by default and places them first',
      (tester) async {
    await tester.pumpWidget(app());
    // Mock streams/futures carry kMockLatency (~300ms).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Capital One Data Breach'), findsOneWidget);
    expect(find.text('Facebook Data Privacy Settlement'), findsOneWidget);

    final expiredDy =
        tester.getTopLeft(find.text('Capital One Data Breach')).dy;
    final activeDy =
        tester.getTopLeft(find.text('Facebook Data Privacy Settlement')).dy;
    expect(expiredDy, lessThan(activeDy));
  });

  testWidgets('toggling Show Expired hides expired lawsuits',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Capital One Data Breach'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Capital One Data Breach'), findsNothing);
  });

  testWidgets('registered users see personal claim states on the home feed',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        submittedClaimIdsProvider.overrideWith((ref) => <String>[]),
      ],
    );
    addTearDown(container.dispose);
    container.read(accountProvider.notifier).register();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: buildTheme(),
          routerConfig: buildRouter(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Payout Received'), findsOneWidget);
    expect(find.text('Claim Filed'), findsOneWidget);
    expect(find.text('Not Eligible'), findsOneWidget);
    expect(find.textContaining('Closed'), findsWidgets);
  });
}
