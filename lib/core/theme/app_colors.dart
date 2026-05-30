import 'package:flutter/material.dart';

/// Centralized color tokens for the ClaimPal "Legal Ledger" design system.
///
/// Values are sourced from
/// `stitch_class_action_settlement_tracker/legal_ledger/DESIGN.md` and
/// consolidate the previously-private palette used by the claim tracker screen.
abstract final class AppColors {
  /// Deep, authoritative navy. Primary brand / actions (DESIGN.md primary).
  static const Color primary = Color(0xFF1A365D);

  /// Primary container surface (DESIGN.md primary-container).
  static const Color primaryContainer = Color(0xFF1A365D);

  /// Vivid emerald used for "Active" statuses and positive progress.
  static const Color success = Color(0xFF10B981);

  /// Darker emerald used for solid success actions / payout values.
  static const Color successDark = Color(0xFF007A4D);

  /// Soft slate for secondary info, archived settlements, disabled states.
  static const Color expired = Color(0xFF718096);

  /// Cool, near-white app background (DESIGN.md background).
  static const Color background = Color(0xFFF7FAFC);

  /// Pure white card / sheet surface.
  static const Color surface = Color(0xFFFFFFFF);

  /// Low-emphasis tonal container (e.g. expired cards).
  static const Color surfaceContainerLow = Color(0xFFF1F4F6);

  /// Default outline color.
  static const Color outline = Color(0xFF74777F);

  /// Lighter outline used for card / divider borders.
  static const Color outlineVariant = Color(0xFFC4C6CF);

  /// Primary text color on light surfaces.
  static const Color onSurface = Color(0xFF181C1E);

  /// Muted secondary text.
  static const Color mutedText = Color(0xFF6F767D);

  /// Error / destructive color.
  static const Color error = Color(0xFFBA1A1A);

  /// Brand navy used for the logo/wordmark in the claim tracker.
  static const Color navy = Color(0xFF0F172A);
}
