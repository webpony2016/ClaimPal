import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Inter-based type scale for the "Legal Ledger" design system.
///
/// Sizes, weights, line-heights and letter-spacing are sourced from
/// `stitch_class_action_settlement_tracker/legal_ledger/DESIGN.md`.
///
/// `letterSpacing` is expressed in logical pixels (em * fontSize) and
/// `height` is a multiplier (lineHeight / fontSize), per Flutter's API.
abstract final class AppTextStyles {
  /// 32 / 700, -0.02em, 40px line-height.
  static TextStyle get headlineLg => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.64, // -0.02em * 32
    height: 40 / 32,
    color: AppColors.onSurface,
  );

  /// 24 / 600, -0.01em, 32px line-height.
  static TextStyle get headlineMd => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24, // -0.01em * 24
    height: 32 / 24,
    color: AppColors.onSurface,
  );

  /// 20 / 600, 28px line-height.
  static TextStyle get headlineSm => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: AppColors.onSurface,
  );

  /// 18 / 400, 28px line-height.
  static TextStyle get bodyLg => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    color: AppColors.onSurface,
  );

  /// 16 / 400, 24px line-height.
  static TextStyle get bodyMd => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurface,
  );

  /// 14 / 400, 20px line-height.
  static TextStyle get bodySm => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.onSurface,
  );

  /// 14 / 600, 0.05em, 16px line-height.
  static TextStyle get labelLg => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.7, // 0.05em * 14
    height: 16 / 14,
    color: AppColors.onSurface,
  );

  /// 12 / 500, 16px line-height.
  static TextStyle get labelSm => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: AppColors.onSurface,
  );
}
