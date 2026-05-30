import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/core/theme/app_colors.dart';

void main() {
  test('AppColors exposes the Legal Ledger palette', () {
    expect(AppColors.primary, const Color(0xFF1A365D));
    expect(AppColors.success, const Color(0xFF10B981));
    expect(AppColors.background, const Color(0xFFF7FAFC));
    expect(AppColors.expired, const Color(0xFF718096));
  });
}
