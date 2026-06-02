import 'package:claimpal/core/router/app_router.dart';
import 'package:claimpal/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/google_fonts_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupGoogleFontsForTesting();

  Future<void> pumpTracker(WidgetTester tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: buildTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.go('/tracker');
    // Mock streams/futures carry kMockLatency (~300ms).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('hides expired settlements by default',
      (tester) async {
    await pumpTracker(tester);
    expect(find.text('Capital One Data Breach'), findsNothing);
  });

  testWidgets('shows received payout total while expired claims are hidden',
      (tester) async {
    await pumpTracker(tester);

    expect(find.text('Received payouts'), findsOneWidget);
    expect(find.text('\$25.00'), findsOneWidget);
  });

  testWidgets('renders expired settlements above active ones when enabled',
      (tester) async {
    await pumpTracker(tester);

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final expiredDy =
        tester.getTopLeft(find.text('Capital One Data Breach')).dy;
    final activeDy =
        tester.getTopLeft(find.text('Facebook Data Privacy Settlement')).dy;

    expect(expiredDy, lessThan(activeDy));
  });

  testWidgets('highlights a received payout, even within the expired list',
      (tester) async {
    await pumpTracker(tester);

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // capital-one-breach is seeded as paid.
    expect(find.text('Payout Received'), findsOneWidget);
  });

  testWidgets('marks a filed claim with a progress stepper', (tester) async {
    await pumpTracker(tester);
    // fitbit-heart-rate is seeded as filed (in progress).
    expect(find.text('Claim Filed'), findsOneWidget);
    expect(find.text('Court Review'), findsWidgets);
  });

  testWidgets('shows an editable not-eligible treatment', (tester) async {
    await pumpTracker(tester);
    // tmobile-data-breach is seeded as ineligible.
    expect(find.text('Not Eligible'), findsOneWidget);
    expect(find.text('Review Eligibility'), findsOneWidget);
  });

  testWidgets('shows a deadline date on each card', (tester) async {
    await pumpTracker(tester);
    expect(find.textContaining('Deadline'), findsWidgets);

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining('Closed'), findsWidgets);
  });
}
