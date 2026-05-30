import 'package:claimpal/core/router/app_router.dart';
import 'package:claimpal/core/theme/app_theme.dart';
import 'package:claimpal/features/home/guest_home_screen.dart';
import 'package:claimpal/features/pricing/pricing_screen.dart';
import 'package:claimpal/features/home/tracker_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/google_fonts_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupGoogleFontsForTesting();

  Widget appWith(GoRouter router) => MaterialApp.router(
        theme: buildTheme(),
        routerConfig: router,
      );

  testWidgets('initial location renders the guest home', (tester) async {
    await tester.pumpWidget(appWith(buildRouter()));
    await tester.pumpAndSettle();

    expect(find.byType(GuestHomeScreen), findsOneWidget);
  });

  testWidgets('navigating to /pricing renders the pricing screen',
      (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(appWith(router));
    await tester.pumpAndSettle();

    router.go('/pricing');
    await tester.pumpAndSettle();

    expect(find.byType(PricingScreen), findsOneWidget);
  });

  testWidgets('shell route renders a tab branch with bottom navigation',
      (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(appWith(router));
    await tester.pumpAndSettle();

    router.go('/tracker');
    await tester.pumpAndSettle();

    expect(find.byType(TrackerHomeScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
