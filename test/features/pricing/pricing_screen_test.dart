import 'package:claimpal/core/theme/app_theme.dart';
import 'package:claimpal/data/models/user_account.dart';
import 'package:claimpal/features/account/account_provider.dart';
import 'package:claimpal/features/pricing/pricing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/google_fonts_test_setup.dart';

Widget _app(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: buildTheme(),
      home: const PricingScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupGoogleFontsForTesting();

  testWidgets('shows the three plan tiers and monthly prices', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    // Plans future carries kMockLatency (~300ms).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Starter'), findsOneWidget);
    expect(find.text('Plus'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);

    expect(find.text('\$0.00'), findsOneWidget);
    expect(find.text('\$2.99'), findsOneWidget);
    expect(find.text('\$5.99'), findsOneWidget);
  });

  testWidgets('tapping a non-current plan upgrades the account tier',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Default guest tier is starter, so Plus shows an "Upgrade" button.
    expect(container.read(accountProvider).tier, SubscriptionTier.starter);

    await tester.pumpWidget(_app(container));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // The starter card is the current plan (disabled); Plus/Pro show Upgrade.
    final upgradeButton = find.widgetWithText(ElevatedButton, 'Upgrade').first;
    await tester.ensureVisible(upgradeButton);
    await tester.pumpAndSettle();
    await tester.tap(upgradeButton);
    await tester.pump();

    expect(container.read(accountProvider).tier, SubscriptionTier.plus);
    expect(find.text('Upgraded to Plus'), findsOneWidget);
  });
}
