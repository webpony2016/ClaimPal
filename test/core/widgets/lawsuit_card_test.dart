import 'package:claimpal/core/theme/app_theme.dart';
import 'package:claimpal/core/widgets/lawsuit_card.dart';
import 'package:claimpal/data/models/lawsuit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/google_fonts_test_setup.dart';

const _activeLawsuit = Lawsuit(
  id: 'fb-privacy',
  title: 'Facebook Data Privacy Settlement',
  brand: 'Facebook',
  category: LawsuitCategory.privacy,
  status: LawsuitStatus.active,
  payoutLabel: 'Estimated Payout',
  payoutValue: 'Up to \$350',
  deadline: null,
  expiredDaysAgo: null,
  eligibility: 'Anyone who used Facebook between 2007 and 2022.',
  requiredProof: <String>['Account email'],
);

const _expiredLawsuit = Lawsuit(
  id: 'capital-one',
  title: 'Capital One Data Breach',
  brand: 'Capital One',
  category: LawsuitCategory.finance,
  status: LawsuitStatus.expired,
  payoutLabel: 'Final Settlement',
  payoutValue: '\$25.00',
  deadline: null,
  expiredDaysAgo: 12,
  eligibility: 'Affected cardholders.',
  requiredProof: <String>[],
);

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: buildTheme(),
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(setupGoogleFontsForTesting);

  testWidgets('active lawsuit renders title and an enabled File Claim button',
      (tester) async {
    await tester.pumpWidget(
      _wrap(LawsuitCard(lawsuit: _activeLawsuit, onTap: () {})),
    );

    expect(find.text('Facebook Data Privacy Settlement'), findsOneWidget);

    final fileClaim = find.widgetWithText(ElevatedButton, 'File Claim');
    expect(fileClaim, findsOneWidget);
    final button = tester.widget<ElevatedButton>(fileClaim);
    expect(button.onPressed, isNotNull);
  });

  testWidgets('expired lawsuit has no enabled File Claim action',
      (tester) async {
    await tester.pumpWidget(
      _wrap(LawsuitCard(lawsuit: _expiredLawsuit, onTap: () {})),
    );

    // No primary "File Claim" button at all in the expired state.
    expect(find.widgetWithText(ElevatedButton, 'File Claim'), findsNothing);
    // Expired CTA copy is present but non-interactive.
    expect(find.text('View Final Verdict'), findsOneWidget);
  });
}
