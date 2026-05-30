import 'package:claimpal/core/theme/app_theme.dart';
import 'package:claimpal/core/widgets/privacy_badge.dart';
import 'package:claimpal/features/referral/referral_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/google_fonts_test_setup.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/referral',
      routes: <RouteBase>[
        GoRoute(
          path: '/referral',
          builder: (context, state) => const ReferralScreen(),
        ),
        GoRoute(
          path: '/wallet',
          builder: (context, state) => const Text('WALLET'),
        ),
      ],
    );

Widget _app() => ProviderScope(
      child: MaterialApp.router(
        theme: buildTheme(),
        routerConfig: _router(),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupGoogleFontsForTesting();

  testWidgets('shows earnings, the referral offer copy and a PrivacyBadge',
      (tester) async {
    await tester.pumpWidget(_app());
    // Rewards future carries kMockLatency (~300ms).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('TOTAL EARNED'), findsOneWidget);
    expect(find.text('\$120.00'), findsOneWidget);

    expect(
      find.text('Give 1 Month, Get 1 Month. Unlimited times.'),
      findsOneWidget,
    );

    expect(find.byType(PrivacyBadge), findsOneWidget);
  });
}
