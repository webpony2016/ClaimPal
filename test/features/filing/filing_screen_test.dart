import 'package:claimpal/core/theme/app_theme.dart';
import 'package:claimpal/features/filing/filing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/google_fonts_test_setup.dart';

Widget _wrap(String lawsuitId) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildTheme(),
      home: FilingScreen(lawsuitId: lawsuitId),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupGoogleFontsForTesting();

  testWidgets('shows the AI Autofill tag, prefilled name and disabled Next',
      (tester) async {
    await tester.pumpWidget(_wrap('facebook-data-privacy'));
    // Mock repo getDraft has ~300ms latency.
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('AI Autofill Ready'), findsOneWidget);
    expect(find.text('Jordan Smith'), findsOneWidget);

    final next = find.widgetWithText(ElevatedButton, 'Next');
    expect(next, findsOneWidget);
    expect(tester.widget<ElevatedButton>(next).onPressed, isNull);
  });
}
