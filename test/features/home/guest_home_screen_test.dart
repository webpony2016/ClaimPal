import 'package:claimpal/core/router/app_router.dart';
import 'package:claimpal/core/theme/app_theme.dart';
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

  testWidgets('shows active lawsuits and hides expired by default',
      (tester) async {
    await tester.pumpWidget(app());
    // Mock streams/futures carry kMockLatency (~300ms).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Facebook Data Privacy Settlement'), findsOneWidget);
    expect(find.text('Capital One Data Breach'), findsNothing);
  });

  testWidgets('toggling Show Expired reveals an expired lawsuit',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Capital One Data Breach'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Capital One Data Breach'), findsOneWidget);
  });
}
