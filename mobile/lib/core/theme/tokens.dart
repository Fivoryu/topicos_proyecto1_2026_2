import 'package:flutter/material.dart';

/// Semantic Flutter mirrors of the shared web design tokens.
abstract final class DesignTokens {
  static const warmSurface = Color(0xFFFFF9F2);
  static const cardSurface = Color(0xFFFFFFFF);
  static const contentPrimary = Color(0xFF1F2937);
  static const contentMuted = Color(0xFF4B5563);
  static const brandPrimary = Color(0xFF4338CA);
  static const brandPrimaryStrong = Color(0xFF312E81);
  static const financeCredit = Color(0xFF166534);
  static const financeDebt = Color(0xFF9F1239);
  static const stateError = Color(0xFF991B1B);
  static const borderDefault = Color(0xFFD6D3D1);
  static const focusRing = Color(0xFF7C3AED);

  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 16.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;
}

typedef ThemeTokens = DesignTokens;
typedef AppTokens = DesignTokens;
