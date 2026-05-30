import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/core/theme/app_colors.dart';
import 'package:claimpal/core/theme/app_theme.dart';

import '../../helpers/google_fonts_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupGoogleFontsForTesting();

  group('buildTheme', () {
    late ThemeData theme;

    setUp(() {
      theme = buildTheme();
    });

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('color scheme overrides brand colors exactly', () {
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.surface, AppColors.surface);
      expect(theme.colorScheme.error, AppColors.error);
    });

    test('scaffold background matches the design background', () {
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });
  });
}
