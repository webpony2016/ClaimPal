import 'package:claimpal/core/theme/app_theme.dart';
import 'package:claimpal/features/detail/lawsuit_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/google_fonts_test_setup.dart';

Widget _wrap(String lawsuitId) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildTheme(),
      home: LawsuitDetailScreen(lawsuitId: lawsuitId),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupGoogleFontsForTesting();

  testWidgets('renders the title and File Claim CTA for a known lawsuit',
      (tester) async {
    await tester.pumpWidget(_wrap('facebook-data-privacy'));
    await tester.pumpAndSettle();

    expect(find.text('Facebook Data Privacy Settlement'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'File Claim'), findsOneWidget);
  });

  testWidgets('shows the not-found state for a bogus id', (tester) async {
    await tester.pumpWidget(_wrap('does-not-exist'));
    await tester.pumpAndSettle();

    expect(find.text('Lawsuit not found'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'File Claim'), findsNothing);
  });

  testWidgets('expired lawsuit shows a disabled CTA instead of File Claim',
      (tester) async {
    await tester.pumpWidget(_wrap('equifax-data-settlement'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'File Claim'), findsNothing);
    final disabled =
        find.widgetWithText(ElevatedButton, 'Claim Window Closed');
    expect(disabled, findsOneWidget);
    expect(tester.widget<ElevatedButton>(disabled).onPressed, isNull);
  });
}
