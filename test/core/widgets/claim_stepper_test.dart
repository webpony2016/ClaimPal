import 'package:claimpal/core/theme/app_theme.dart';
import 'package:claimpal/core/widgets/claim_stepper.dart';
import 'package:claimpal/data/models/claim_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/google_fonts_test_setup.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: buildTheme(),
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(setupGoogleFontsForTesting);

  testWidgets('court review marks the first two steps complete',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ClaimStepper(
          progress: ClaimProgress(currentStage: ClaimStage.courtReview),
        ),
      ),
    );

    // AI Submitted + Court Review are complete -> two check icons.
    expect(find.byIcon(Icons.check), findsNWidgets(2));

    // All four step labels render.
    expect(find.text('AI Submitted'), findsOneWidget);
    expect(find.text('Court Review'), findsOneWidget);
    expect(find.text('Settlement Approved'), findsOneWidget);
    expect(find.text('Payout Sent'), findsOneWidget);
  });
}
